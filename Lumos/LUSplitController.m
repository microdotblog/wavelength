//
//  LUSplitController.m
//  Lumos
//
//  Created by Manton Reece on 3/20/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSplitController.h"

#import "LUSegment.h"
#import "LUAudioClip.h"
#import "LUNotifications.h"
#import <AVFoundation/AVFoundation.h>

@implementation LUSplitController

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupButtons];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self setupGraph];
}

- (void) setupButtons
{
	self.splitButton.layer.cornerRadius = 28.0;
	self.splitButton.layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
	self.splitButton.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1.0].CGColor;
	self.splitButton.layer.borderWidth = 1.0;
	self.splitButton.clipsToBounds = YES;
}

- (void) setupGraph
{
	NSURL* audio_url = [NSURL fileURLWithPath:self.segment.path];
	self.clip = [[LUAudioClip alloc] initWithDestination:audio_url];

	CGFloat w = [self bestWidthForDuration:self.clip.duration];
	CGSize size = CGSizeMake (w, self.scrollView.bounds.size.height);

	CGRect container_r = CGRectMake ([self bestPadding], 50, size.width, size.height - 100);
	CGRect audio_r = CGRectMake (0, 0, size.width, size.height - 100);

	UIView* v = [self.clip requestAudioInputView];
	v.frame = audio_r;

	UIView* container = [[UIView alloc] initWithFrame:container_r];
	container.layer.shadowColor = [UIColor lightGrayColor].CGColor;
	container.layer.shadowOpacity = 0.3;
	container.layer.shadowRadius = 3.0;
	container.layer.shadowOffset = CGSizeMake (0, 0);
	container.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:container.bounds cornerRadius:7.0].CGPath;
	container.layer.backgroundColor = [UIColor whiteColor].CGColor;
	container.layer.cornerRadius = 7.0;
	[container addSubview:v];
	
	[self.scrollView addSubview:container];
	[self.scrollView setContentSize:CGSizeMake (size.width + ([self bestPadding] * 2), size.height)];
}

- (CGFloat) bestWidthForDuration:(NSTimeInterval)duration
{
	// 300 pixels wide per second of audio
	return 300.0 * duration;
}

- (CGFloat) bestPadding
{
	return self.view.bounds.size.width / 2.0;
}

- (NSTimeInterval) timeOffsetForScrollPosition:(CGFloat)x
{
//	CGFloat offset_x = x - [self bestPadding];
	CGFloat w = [self bestWidthForDuration:self.clip.duration];
	CGFloat fraction = x / w;
	return fraction * self.clip.duration;
}

- (void) splitAsset:(AVAsset *)asset withRange:(CMTimeRange)range toFile:(NSString *)path completion:(void (^)(void))handler
{
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.outputURL = [NSURL fileURLWithPath:path];
    exporter.timeRange = range;
	
    [exporter exportAsynchronouslyWithCompletionHandler:^{
    	if (exporter.status == AVAssetExportSessionStatusCompleted) {
			handler();
		}
		else if (exporter.status == AVAssetExportSessionStatusFailed) {
			// ...
		}
		else if (exporter.status == AVAssetExportSessionStatusCancelled) {
			// ...
		}
	}];
}

- (void) splitAtSeconds:(NSTimeInterval)seconds
{
	CMTime part1_start = CMTimeMake(0, 1);
	CMTime part1_end = CMTimeMake(seconds, 1);
	CMTimeRange part1_range = CMTimeRangeFromTimeToTime (part1_start, part1_end);

	CMTime part2_start = CMTimeMake(seconds, 1);
	CMTime part2_end = CMTimeMake(self.clip.duration, 1);
	CMTimeRange part2_range = CMTimeRangeFromTimeToTime (part2_start, part2_end);
	
	NSString* filename1 = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"m4a"];
	NSString* filename2 = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"m4a"];

	self.part1File = [[self.segment.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename1];
	self.part2File = [[self.segment.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename2];

	AVAsset* asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.segment.path]];
	[self splitAsset:asset withRange:part1_range toFile:self.part1File completion:^{
		self.isExportedPart1 = YES;
		[self checkFinished];
	}];
	[self splitAsset:asset withRange:part2_range toFile:self.part2File completion:^{
		self.isExportedPart2 = YES;
		[self checkFinished];
	}];
}

- (void) checkFinished
{
    dispatch_async (dispatch_get_main_queue(), ^{
		if (self.isExportedPart1 && self.isExportedPart2) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kReplaceSegmentNotification object:self userInfo:@{
				kReplaceSegmentOriginalKey: self.segment,
				kReplaceSegmentNewArrayKey: @[
					self.part1File,
					self.part2File
				]
			}];
			[self.navigationController popViewControllerAnimated:YES];
		}
	});
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	NSTimeInterval seconds = [self timeOffsetForScrollPosition:scrollView.contentOffset.x];
	self.splitSeconds = seconds;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
}

- (IBAction) play:(id)sender
{
}

- (IBAction) split:(id)sender
{
	[self splitAtSeconds:self.splitSeconds];
}

- (IBAction) delete:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kReplaceSegmentNotification object:self userInfo:@{
		kReplaceSegmentOriginalKey: self.segment,
		kReplaceSegmentNewArrayKey: @[]
	}];
	[self.navigationController popViewControllerAnimated:YES];
}

@end
