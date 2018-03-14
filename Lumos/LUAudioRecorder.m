//
//  LUAudioRecorder.m
//  Lumos
//
//  Created by Jonathan Hays on 3/13/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAudioRecorder.h"
#import <EZAudio/EZAudio.h>

@import AVFoundation;

@interface LUAudioRecorder()<EZMicrophoneDelegate, EZRecorderDelegate, EZAudioPlayerDelegate>
	@property (nonatomic, strong) NSURL* destination;
	@property (nonatomic, strong) EZAudioPlot* audioPlot;
	@property (nonatomic, strong) EZMicrophone* microphone;
	@property (nonatomic, strong) EZRecorder* recorder;
	@property (nonatomic, strong) EZAudioPlayer *player;
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
	
	NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSString* dateString = [now description];
	NSString* fileName = [NSString stringWithFormat:@"%@.caf", dateString];
	
	NSURL* recorderFilePath = [documentsDirectory URLByAppendingPathComponent:fileName];
	return recorderFilePath;
}

+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithDestination:(NSURL*)destinationUrl
{
	self = [super init];
	if (self)
	{
		self.destination = destinationUrl;
		[self setup];
	}
	
	return self;
}

- (BOOL) setup
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

	self.audioPlot = [[EZAudioPlot alloc] init];
    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldOptimizeForRealtimePlot = YES;

    //
    // Create the microphone
    //
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
	self.microphone.delegate = self;
	
    self.player = [EZAudioPlayer audioPlayerWithDelegate:self];
	
	[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];

    //
    // Start the microphone
    //
    [self.microphone startFetchingAudio];
	

	return true;
}

- (UIImage*) renderWaveImage:(CGSize)size
{
	CALayer* layer = self.audioPlot.waveformLayer;
	CGRect bounds = layer.bounds;
	layer.bounds = CGRectMake(0, 0, size.width, size.height);
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
	
    layer.bounds = bounds;

    return outputImage;
}

- (UIView*) requestAudioInputView
{
	return self.audioPlot;
}

- (void) record
{
    self.audioPlot.plotType        = EZPlotTypeRolling;
    self.audioPlot.shouldFill      = YES;
    self.audioPlot.shouldMirror    = YES;

	self.recorder = [EZRecorder recorderWithURL:self.destination
                                       clientFormat:[self.microphone audioStreamBasicDescription]
                                           fileType:EZRecorderFileTypeM4A
                                           delegate:self];
}

- (void) play
{
    EZAudioFile* audioFile = [EZAudioFile audioFileWithURL:self.destination];
    [self.player playAudioFile:audioFile];
}

- (void) stop
{
	[self.recorder closeAudioFile];
	self.recorder.delegate = nil;
	
    [self.microphone stopFetchingAudio];

	[self.player pause];
	[self.player seekToFrame:0];

	self.audioPlot.plotType = EZPlotTypeBuffer;

	EZAudioFile *audioFile = [EZAudioFile audioFileWithURL:self.destination];
	EZAudioFloatData* data = [audioFile getWaveformData];
	
	[self.audioPlot setSampleData:data.buffers[0]  length:data.bufferSize];
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

//------------------------------------------------------------------------------
#pragma mark - EZAudioPlayerDelegate
//------------------------------------------------------------------------------

- (void) audioPlayer:(EZAudioPlayer *)audioPlayer playedAudio:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels inAudioFile:(EZAudioFile *)audioFile
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [weakSelf.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

- (void)audioPlayer:(EZAudioPlayer *)audioPlayer updatedPosition:(SInt64)framePosition inAudioFile:(EZAudioFile *)audioFile
{
}

- (void)audioPlayer:(EZAudioPlayer *)audioPlayer reachedEndOfAudioFile:(EZAudioFile *)audioFile
{
	if (self.playbackCompleteCallback)
		self.playbackCompleteCallback(self);
}


@end
