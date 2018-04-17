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
#import "UUAlert.h"

@implementation LUSplitController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupDefaults];
	[self setupButtons];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self setupGraph];
}

- (void) setupDefaults
{
	self.splitSeconds = 0.0;
}

- (void) setupButtons
{
	self.splitButton.layer.cornerRadius = 28.0;
	self.splitButton.layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
	self.splitButton.clipsToBounds = YES;

	self.zoomButton.layer.cornerRadius = 28.0;
	self.zoomButton.layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
	self.zoomButton.clipsToBounds = YES;
}

- (void) setupGraph
{
	if (!self.clip) {
		NSURL* audio_url = [NSURL fileURLWithPath:self.segment.path];
		self.clip = [[LUAudioClip alloc] initWithDestination:audio_url];
	}

	CGFloat w = [self bestWidthForDuration:self.clip.duration];
	CGSize size = CGSizeMake (w, self.scrollView.bounds.size.height);

	CGFloat vertical_padding = 50;
	if (self.isZoomed) {
		vertical_padding = -200;
	}

	CGRect container_r = CGRectMake ([self bestPadding], vertical_padding, size.width, size.height - (vertical_padding * 2));
	CGRect audio_r = CGRectMake (0, 0, size.width, size.height - (vertical_padding * 2));

	UIView* v = [self.clip requestAudioInputView];
	v.frame = audio_r;
	
	if (self.scrollingContainer == nil) {
		self.scrollingContainer = [[UIView alloc] initWithFrame:container_r];
		self.scrollingContainer.layer.shadowColor = [UIColor lightGrayColor].CGColor;
		self.scrollingContainer.layer.shadowOpacity = 0.3;
		self.scrollingContainer.layer.shadowRadius = 3.0;
		self.scrollingContainer.layer.shadowOffset = CGSizeMake (0, 0);
		self.scrollingContainer.layer.backgroundColor = [UIColor whiteColor].CGColor;
		self.scrollingContainer.layer.cornerRadius = 7.0;
		[self.scrollingContainer addSubview:v];
		[self.scrollView addSubview:self.scrollingContainer];
	}
	else {
		self.scrollingContainer.frame = container_r;
	}

	self.scrollingContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.scrollingContainer.bounds cornerRadius:7.0].CGPath;

	NSTimeInterval preserve_offset = self.splitSeconds;
	[self.scrollView setContentSize:CGSizeMake (size.width + ([self bestPadding] * 2), size.height)];
	self.splitSeconds = preserve_offset;
}

- (void) updatePlayButton
{
	UIImage* img = nil;
	if (self.player) {
		img = [UIImage imageNamed:@"pause"];
	}
	else {
		img = [UIImage imageNamed:@"play"];
	}

	[self.playPauseButton setImage:img forState:UIControlStateNormal];
}

- (CGFloat) bestWidthForDuration:(NSTimeInterval)duration
{
	// 300 points wide per second of audio (or 900 zoomed)
	if (self.isZoomed) {
		return 900.0 * duration;
	}
	else {
		return 300.0 * duration;
	}
}

- (CGFloat) bestPadding
{
	return self.view.bounds.size.width / 2.0;
}

- (NSTimeInterval) timeOffsetForScrollPosition:(CGFloat)x
{
	CGFloat w = [self bestWidthForDuration:self.clip.duration];
	CGFloat fraction = 0.0;
	if (x > 0.0) {
		fraction = x / w;
	}
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
			NSLog (@"Error: %@", [exporter.error localizedDescription]);
			[UUAlertViewController uuShowOneButtonAlert:@"Split Failed" message:@"The audio file could not be split." button:@"OK" completionHandler:NULL];
		}
		else if (exporter.status == AVAssetExportSessionStatusCancelled) {
			NSLog (@"Export cancelled");
		}
	}];
}

- (void) splitAtSeconds:(NSTimeInterval)seconds
{
	CMTime part1_start = CMTimeMakeWithSeconds (0, NSEC_PER_SEC);
	CMTime part1_end = CMTimeMakeWithSeconds (seconds, NSEC_PER_SEC);
	CMTimeRange part1_range = CMTimeRangeFromTimeToTime (part1_start, part1_end);

	CMTime part2_start = CMTimeMakeWithSeconds (seconds, NSEC_PER_SEC);
	CMTime part2_end = CMTimeMakeWithSeconds (self.clip.duration, NSEC_PER_SEC);
	CMTimeRange part2_range = CMTimeRangeFromTimeToTime (part2_start, part2_end);
	
	NSString* filename1 = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"m4a"];
	NSString* filename2 = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"m4a"];

	self.part1File = [[self.segment.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename1];
	self.part2File = [[self.segment.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename2];

	AVAsset* asset1 = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.segment.path]];
	[self splitAsset:asset1 withRange:part1_range toFile:self.part1File completion:^{
		dispatch_async (dispatch_get_main_queue(), ^{
			AVAsset* asset2 = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.segment.path]];
			[self splitAsset:asset2 withRange:part2_range toFile:self.part2File completion:^{
				dispatch_async (dispatch_get_main_queue(), ^{
					NSDictionary* userInfo = @{
						kReplaceSegmentOriginalKey: self.segment,
						kReplaceSegmentNewArrayKey: @[ self.part1File, self.part2File ]
					};
					
					[[NSNotificationCenter defaultCenter] postNotificationName:kReplaceSegmentNotification object:self userInfo:userInfo];
					
					[self.navigationController popViewControllerAnimated:YES];
				});
			}];
		});
	}];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	NSTimeInterval seconds = [self timeOffsetForScrollPosition:scrollView.contentOffset.x];
	self.splitSeconds = seconds;
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if (self.player) {
		[self.player pause];
		self.player = nil;
		[self updatePlayButton];
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
}

- (void) playerDidFinishPlaying:(NSNotification *)notification
{
	[self play:nil];
	self.splitSeconds = 0.0;
}

- (IBAction) play:(id)sender
{
	if (self.player) {
		[self.player pause];
		self.player = nil;
	}
	else {
		self.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:self.segment.path]];

		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];

		AVPlayerItem* item = self.player.currentItem;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];

		CMTime interval = CMTimeMakeWithSeconds (0.05, NSEC_PER_SEC);
		__weak LUSplitController* weak_self = self;
		[self.player addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time) {
			dispatch_async (dispatch_get_main_queue(), ^{
				[weak_self updatePlaybackForTime:time];
			});
		}];

		CMTime offset = CMTimeMakeWithSeconds (self.splitSeconds, NSEC_PER_SEC);
		[self.player seekToTime:offset];
		[self.player play];
	}
	
	[self updatePlayButton];
}

- (void) updatePlaybackForTime:(CMTime)time
{
	Float64 offset = CMTimeGetSeconds (time);
	[self updatePlaybackForSeconds:offset];
}

- (void) updatePlaybackForSeconds:(NSTimeInterval)offset
{
	CGFloat w = [self bestWidthForDuration:self.clip.duration];
	CGFloat fraction = offset / self.clip.duration;
	if (fraction > 1.0) {
		fraction = 1.0;
	}
	CGFloat x = fraction * w;
	[self.scrollView setContentOffset:CGPointMake (x, 0) animated:NO];

	self.splitSeconds = offset;
}

#pragma mark -

- (IBAction) split:(id)sender
{
	self.splitButton.layer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
	[self splitAtSeconds:self.splitSeconds];
}

- (IBAction) zoom:(id)sender
{
	if (self.isZoomed) {
		self.isZoomed = NO;
		[self.zoomButton setImage:[UIImage imageNamed:@"zoom_in"] forState:UIControlStateNormal];
	}
	else {
		self.isZoomed = YES;
		[self.zoomButton setImage:[UIImage imageNamed:@"zoom_out"] forState:UIControlStateNormal];
	}
	
	[self setupGraph];
	[self updatePlaybackForSeconds:self.splitSeconds];
}

- (IBAction) delete:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:nil message:@"Are you sure you want to delete this segment?" buttonOne:@"Cancel" buttonTwo:@"Delete" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kReplaceSegmentNotification object:self userInfo:@{
				kReplaceSegmentOriginalKey: self.segment,
				kReplaceSegmentNewArrayKey: @[]
			}];
			[self.navigationController popViewControllerAnimated:YES];
		}
	}];
}

@end
