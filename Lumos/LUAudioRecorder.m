//
//  LUAudioRecorder.m
//  Lumos
//
//  Created by Jonathan Hays on 3/13/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAudioRecorder.h"

@import AVFoundation;

@interface LUAudioRecorder()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>
	@property (nonatomic, strong) AVAudioRecorder* recorder;
	@property (nonatomic, strong) AVAudioPlayer* player;
	@property (nonatomic, strong) NSURL* destination;
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

	NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];

	[recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
	[recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
	[recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];

	[recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
	[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
	[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
	
	err = nil;
	self.recorder = [[AVAudioRecorder alloc] initWithURL:self.destination settings:recordSetting error:&err];
	if(!self.recorder)
	{
		NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    	return FALSE;
	}

	//prepare to record
	[self.recorder setDelegate:self];
	[self.recorder prepareToRecord];
	self.recorder.meteringEnabled = YES;

	return true;
}

- (void) record
{
	[self.player stop];
	[self.recorder record];
}

- (void) play
{
	if (self.recorder.isRecording)
	{
		[self.recorder stop];
	}
	
	if (self.player.isPlaying)
	{
		[self.player stop];
	}
	
	//prepare to playback
    NSError* error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.destination error:&error];
    self.player.numberOfLoops = 0;
    self.player.delegate = self;

	BOOL ableToPlay = [self.player prepareToPlay];
	ableToPlay = [self.player play];
	if (!ableToPlay)
	{
		NSLog(@"FAIL TO PLAY!!!");
	}
}

- (void) stop
{
	[self.player stop];
	[self.recorder stop];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	if (self.playbackCompleteCallback)
		self.playbackCompleteCallback(self);
}

@end
