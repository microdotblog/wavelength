//
//  LUExportController.m
//  Wavelength
//
//  Created by Manton Reece on 3/31/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUExportController.h"

#import "LUEpisode.h"
#import "LUNotifications.h"
#import "ExtAudioConverter.h"
#import <AVFoundation/AVFoundation.h>

@implementation LUExportController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.containerView.layer.cornerRadius = 10.0;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self exportWithCompletion:^{
		[self convertToMP3];
	}];
}

- (void) exportWithCompletion:(void (^)(void))handler
{
	NSString* path = self.episode.exportedPath;
	[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];

	AVMutableComposition* composition = self.episode.exportedComposition;
	AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
	exporter.outputURL = [NSURL fileURLWithPath:path];
	exporter.outputFileType = AVFileTypeAppleM4A;
	[exporter exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			if (exporter.status == AVAssetExportSessionStatusCompleted) {
				handler();
			}
		});
	}];
}

- (void) convertToMP3
{
	NSString* mp3_path = [self.episode.exportedPath stringByDeletingLastPathComponent];
	mp3_path = [mp3_path stringByAppendingPathComponent:@"exported.mp3"];
	[[NSFileManager defaultManager] removeItemAtPath:mp3_path error:NULL];
	
	ExtAudioConverter* converter = [[ExtAudioConverter alloc] init];
	converter.inputFile = self.episode.exportedPath;
	converter.outputFile = mp3_path;

//	converter.outputSampleRate = 44100;
//	converter.outputNumberChannels = 1;
//	converter.outputBitDepth = BitDepth_16;

	converter.outputFormatID = kAudioFormatMPEGLayer3;
	converter.outputFileType = kAudioFileMP3Type;

	[converter convert];

	[[NSNotificationCenter defaultCenter] postNotificationName:kFinishedExportNotification object:self userInfo:@{ kFinishedExportFileKey: mp3_path }];
}

@end
