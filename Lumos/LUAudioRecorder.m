//
//  LUAudioRecorder.m
//  Lumos
//
//  Created by Jonathan Hays on 3/19/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAudioRecorder.h"
#import <EZAudio/EZAudio.h>
#import "UUDate.h"
#import "UUString.h"

@import AVFoundation;

// Private declaration
@interface LUAudioClip()
	@property (nonatomic, strong) EZAudioPlot* audioPlot;
@end

@interface LUAudioRecorder()<EZMicrophoneDelegate, EZRecorderDelegate>
	@property (nonatomic, strong) EZMicrophone* microphone;
	@property (nonatomic, strong) EZRecorder* recorder;
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
	
	NSString* timeStampString = [NSString stringWithFormat:@"%@-%@.%@.%@", [now uuIso8601DateString],
																		   [now uuHour],
																		   [now uuMinute],
																		   [now uuSecond]];
	
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
		[self setupRecorder];
	}
	
	return self;
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

	[audioSession setActive:YES error:&err];
	err = nil;
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
	[self.microphone startFetchingAudio];
	
	[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];

	return true;
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
	return self.audioPlot;
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
        [weakSelf.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
		
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
