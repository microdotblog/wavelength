//
//  LUAudioRecorder.m
//  Lumos
//
//  Created by Jonathan Hays on 3/13/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAudioClip.h"
#import <EZAudio/EZAudio.h>
#import "UUDate.h"

@import AVFoundation;

@interface LUAudioClip()<EZAudioPlayerDelegate>
	@property (nonatomic, strong) NSURL* destination;
	@property (nonatomic, strong) EZAudioPlot* audioPlot;
	@property (nonatomic, strong) EZAudioPlayer *player;
	@property (nonatomic, strong) UIImage* thumbnailImage;
	@property (nonatomic, assign) NSTimeInterval duration;
	@property (nonatomic, strong) NSString* durationString;
@end

@implementation LUAudioClip

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithDestination:(NSURL*)destinationUrl
{
	self = [super init];
	if (self)
	{
		self.destination = destinationUrl;

		[self setupPlotAndPlayer];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.destination.path]) {
			[self loadThumbnailImage];
		}
	}
	
	return self;
}

- (void) loadThumbnailImage
{
	NSString* thumbnail_filename = [self.destination lastPathComponent];
	NSURL* thumbnail_base = [self.destination URLByDeletingLastPathComponent];
	thumbnail_filename = [thumbnail_filename stringByAppendingString:@"-thumbnail.png"];
	NSURL* thumbnail_url = [thumbnail_base URLByAppendingPathComponent:thumbnail_filename];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnail_url.path])
	{
		self.thumbnailImage = [UIImage imageWithContentsOfFile:thumbnail_url.path];
	}
	else
	{
		CGSize preview_size = CGSizeMake (150, 54);

		UIImage* image = [self renderWaveImage:preview_size];
		if (image)
		{
			NSData* imageData = UIImagePNGRepresentation(image);
			if (imageData)
			{
				NSError* error = nil;
				[imageData writeToURL:thumbnail_url options:NSDataWritingFileProtectionNone error:&error];
				
				if (error)
				{
					NSLog(@"Error = %@", error);
				}
			}
			
			self.thumbnailImage = image;
		}
		else
		{
			NSLog(@"ERROR! Unable to load or render waveform!");
		}
	}
}

- (BOOL) setupPlotAndPlayer
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
    self.audioPlot.color = [UIApplication sharedApplication].windows.firstObject.tintColor;
    self.audioPlot.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite:0.95 alpha:1.0];
    self.audioPlot.plotType = EZPlotTypeRolling;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
    self.audioPlot.shouldOptimizeForRealtimePlot = NO;

	if ([[NSFileManager defaultManager] fileExistsAtPath:self.destination.path])
	{
    	EZAudioFile* audioFile = [EZAudioFile audioFileWithURL:self.destination];
		EZAudioFloatData* audioData = [audioFile getWaveformData];
		if (audioData)
		{
			[self.audioPlot setSampleData:audioData.buffers[0] length:audioData.bufferSize];
		}
		
		self.duration = audioFile.duration;
		self.durationString = audioFile.formattedDuration;
	}

	[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];

	return true;
}

- (UIImage*) renderWaveImage:(CGSize)size
{
	EZAudioFile* audioFile = [EZAudioFile audioFileWithURL:self.destination];
	EZAudioFloatData* audioData = [audioFile getWaveformData];
	if (audioData)
	{
		[self.audioPlot setSampleData:audioData.buffers[0] length:audioData.bufferSize];
	}

	CGRect previousFrame = self.audioPlot.frame;
	
	self.audioPlot.frame = CGRectMake(0, 0, size.width, size.height);
	[self.audioPlot redraw];

	CALayer* layer = self.audioPlot.waveformLayer;
	CGRect bounds = layer.bounds;
	layer.bounds = CGRectMake(0, 0, size.width, size.height);
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
	
    layer.bounds = bounds;

	self.audioPlot.frame = previousFrame;
	
    return outputImage;
}

- (UIImage*) waveFormImage
{
	if (!self.thumbnailImage)
	{
		[self loadThumbnailImage];
	}
	
	return self.thumbnailImage;
}

- (UIView*) requestAudioInputView
{
	return self.audioPlot;
}

- (void) play
{
	if (!self.player)
	{
		self.player = [EZAudioPlayer audioPlayerWithDelegate:self];
	}
	
    EZAudioFile* audioFile = [EZAudioFile audioFileWithURL:self.destination];
	EZAudioFloatData* data = [audioFile getWaveformData];
	
	[self.audioPlot setSampleData:data.buffers[0]  length:data.bufferSize];

    [self.player playAudioFile:audioFile];
}

- (void) stop
{
	[self.player pause];
	[self.player seekToFrame:0];

	self.audioPlot.plotType = EZPlotTypeRolling;

	EZAudioFile *audioFile = [EZAudioFile audioFileWithURL:self.destination];
	EZAudioFloatData* data = [audioFile getWaveformData];
	
	[self.audioPlot setSampleData:data.buffers[0]  length:data.bufferSize];
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
