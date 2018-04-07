//
//  LUAudioRecorder.m
//  Lumos
//
//  Created by Jonathan Hays on 3/19/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LUNotifications.h"
#import "LUAudioRecorder.h"
#import <EZAudio/EZAudio.h>
#import "UUDate.h"
#import "UUString.h"
#import "UUColor.h"
#import "UUAlert.h"

#import "DPMainEqualizerView.h"
#import "DPCircleWaveEqualizer.h"
#import "DPWaveEqualizerView.h"

@import AVFoundation;

// Private declaration
@interface LUAudioClip()
	@property (nonatomic, strong) EZAudioPlot* audioPlot;
@end

@interface LUAudioRecorder()<EZMicrophoneDelegate, EZRecorderDelegate>
	@property (nonatomic, strong) EZMicrophone* microphone;
	@property (nonatomic, strong) EZRecorder* recorder;
	@property (nonatomic, strong) DPWaveEqualizerView* visualizationView;
	@property (nonatomic, assign) BOOL usingExternalMicrophone;
	@property (nonatomic, strong) NSTimer* checkForUnplugMicrophoneTimer;
@end


@implementation LUAudioRecorder

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


+ (BOOL) canRecord
{
	AVAudioSession* audioSession = [AVAudioSession sharedInstance];

	NSError* err = nil;
	[audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];

	if(err)
	{
		NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    	return FALSE;
	}

	[audioSession setActive:YES error:&err];
	err = nil;
	if(err)
	{
		NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    	return FALSE;
	}

	if (!audioSession.inputAvailable)
	{
		NSLog(@"This device does not have the ability to record.");
    	return FALSE;
	}


	return TRUE;
}

+ (NSURL*) generateTimeStampedFileURL
{
	NSURL* documentsDirectory = [self applicationDocumentsDirectory];
	
	NSDate* now = [NSDate date];
	
	NSString* timeStampString = [now uuIso8601DateTimeString];
	
	NSString* episodeName = [NSString stringWithString:timeStampString];
	NSString* fileName = [timeStampString stringByAppendingString:@".caf"];
	
	NSURL* episodeDirectory = nil;
	BOOL found = NO;
	NSInteger i = 1;
	while (!found) {
		episodeDirectory = [documentsDirectory URLByAppendingPathComponent:episodeName];
		if ([[NSFileManager defaultManager] fileExistsAtPath:episodeDirectory.path]) {
			i++;
			episodeName = [NSString stringWithFormat:@"%@-%ld", [now uuIso8601DateTimeString], (long)i];
			episodeName = [episodeName uuUrlEncoded];
		}
		else {
			found = YES;
			[[NSFileManager defaultManager] createDirectoryAtURL:episodeDirectory withIntermediateDirectories:NO attributes:nil error:NULL];
		}
	}
	
	NSURL* recorderFilePath = [episodeDirectory URLByAppendingPathComponent:fileName];
	return recorderFilePath;
}

+ (NSURL*) applicationDocumentsDirectory
{
    NSURL* url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	//NSLog(@"Documents Directory = %@", url);
	return url;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (instancetype) initWithDestination:(NSURL*)destinationUrl
{
	self = [super initWithDestination:destinationUrl];
	if (self)
	{
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(accessoryDidConnect:) name:AVAudioSessionRouteChangeNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(accessoryDidConnect:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
		
		[self setupRecorder];
	}
	
	return self;
}

- (void) accessoryDidConnect:(NSNotification*)notification
{
	NSNumber* reason = [notification.userInfo objectForKey:@"AVAudioSessionRouteChangeReasonKey"];
	if (reason.integerValue == AVAudioSessionRouteChangeReasonNewDeviceAvailable)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:kRecordingDeviceChangedNotification object:nil];
		});
	}
	else if (reason.integerValue == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:kRecordingDeviceChangedNotification object:nil];
		});
	}
}

- (BOOL) setupRecorder
{
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];

	NSError *err = nil;
	[audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];

	if(err)
	{
		NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    	return FALSE;
	}

    //
    // Create the microphone
    //
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
	self.microphone.delegate = self;
	
	NSArray* devices = [EZAudioDevice inputDevices];
	for (EZAudioDevice* device in devices) {
		if ([device.port.portType isEqualToString:AVAudioSessionPortUSBAudio] ||
			[device.port.portType isEqualToString:AVAudioSessionPortBluetoothHFP])
		{
			self.customDeviceName = device.port.portName;
			[self.microphone setDevice:device];
			self.usingExternalMicrophone = YES;
			self.checkForUnplugMicrophoneTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimerForExternalMicrophone) userInfo:nil repeats:YES];
		}
	}

	[audioSession setActive:YES error:&err];
	err = nil;
	if(err)
	{
		NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    	return FALSE;
	}

	[self.microphone startFetchingAudio];

	[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];

	self.audioPlot.plotType = EZPlotTypeBuffer;
	//self.audioPlot.color = [UIColor whiteColor];
	self.audioPlot.shouldFill = YES;
	self.audioPlot.shouldMirror = YES;
	self.audioPlot.gain = 3.0;
	
	DPEqualizerSettings* settings = [DPEqualizerSettings createByType: DPCircleWave];
	
    settings.equalizerBinColors = [[NSMutableArray alloc] initWithObjects:[UIColor clearColor], nil];
    settings.lowFrequencyColors = [[NSMutableArray alloc] initWithObjects:[UIApplication sharedApplication].windows.firstObject.tintColor, nil];
    settings.hightFrequencyColors = [[NSMutableArray alloc] initWithObjects:[UIApplication sharedApplication].windows.firstObject.tintColor, nil];
    settings.equalizerBackgroundColors = [[NSMutableArray alloc] initWithObjects:[UIColor clearColor], nil];
    settings.fillGraph = NO;

	self.visualizationView = [[DPWaveEqualizerView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 120) andSettings:settings];
	//self.visualizationView.equalizerBinColor = [UIColor redColor];
	//self.visualizationView.equalizerBackgroundColor = [UIColor greenColor];

	return true;
}

- (void) handleTimerForExternalMicrophone
{
	self.usingExternalMicrophone = NO;
	NSArray* devices = [EZAudioDevice inputDevices];
	for (EZAudioDevice* device in devices)
	{
		if ([device.port.portType isEqualToString:AVAudioSessionPortUSBAudio] ||
			[device.port.portType isEqualToString:AVAudioSessionPortBluetoothHFP])
		{
			self.usingExternalMicrophone = YES;
		}
	}
	
	if (!self.usingExternalMicrophone)
	{
		[self.checkForUnplugMicrophoneTimer invalidate];
		self.checkForUnplugMicrophoneTimer = nil;

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:kRecordingDeviceChangedNotification object:nil];
		});
	}
}

- (void) record
{
	self.recorder = [EZRecorder recorderWithURL:self.destination
                                       clientFormat:[self.microphone audioStreamBasicDescription]
                                           fileType:EZRecorderFileTypeM4A
                                           delegate:self];
	
	[self.microphone startFetchingAudio];
}

- (void) stop
{
    [self.microphone stopFetchingAudio];

	[self.recorder closeAudioFile];
	self.recorder.delegate = nil;
	
	[super stop];
}

- (UIView*) requestAudioInputView
{
	return self.visualizationView;
	//return self.audioPlot;
}


- (void)microphone:(EZMicrophone *)microphone hasAudioReceived:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    //
    // Getting audio data as an array of float buffer arrays. What does that mean?
    // Because the audio is coming in as a stereo signal the data is split into
    // a left and right channel. So buffer[0] corresponds to the float* data
    // for the left channel while buffer[1] corresponds to the float* data
    // for the right channel.
    //

    //
    // See the Thread Safety warning above, but in a nutshell these callbacks
    // happen on a separate audio thread. We wrap any UI updating in a GCD block
    // on the main thread to avoid blocking that audio flow.
    //
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        // All the audio plot needs is the buffer data (float*) and the size.
        // Internally the audio plot will handle all the drawing related code,
        // history management, and freeing its own resources.
        // Hence, one badass line of code gets you a pretty plot :)
        //
        //[weakSelf.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
		[weakSelf.visualizationView updateBuffer:buffer[0] withBufferSize:bufferSize];
		
        if (weakSelf.recordProgressCallback)
        {
        	NSString* timeString = weakSelf.recorder.formattedCurrentTime;
        	weakSelf.recordProgressCallback(timeString);
		}
    });
}

- (void) microphone:(EZMicrophone *)microphone hasBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    //
    // Getting audio data as a buffer list that can be directly fed into the
    // EZRecorder. This is happening on the audio thread - any UI updating needs
    // a GCD main queue block. This will keep appending data to the tail of the
    // audio file.
    //
    if (self.recorder)
    {
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
}

@end
