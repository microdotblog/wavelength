//
//  LUEditController.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUEditController.h"

#import "LUEpisode.h"
#import "LUSegment.h"
#import "LUSegmentCell.h"
#import "LUAudioClip.h"
#import "LUAudioRecorder.h"
#import "LUSplitController.h"
#import <EZAudio/EZAudio.h>

static CGFloat const kCellPadding = 10.0;
static const NSString* kItemStatusContext;

@interface LUEditController ()<UICollectionViewDragDelegate, UICollectionViewDropDelegate>
	@property (nonatomic, assign) BOOL isInRecordMode;
	@property (nonatomic, strong) LUAudioRecorder* audioRecorder;
	@property (nonatomic, strong) IBOutlet UIView* waveFormViewContainer;
@end

@implementation LUEditController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.collectionView.dragDelegate = self;
	self.collectionView.dropDelegate = self;
	self.collectionView.dragInteractionEnabled = YES;

	UITapGestureRecognizer* double_tap_gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapCollectionView:)];
	double_tap_gesture.numberOfTapsRequired = 2;
	[self.collectionView addGestureRecognizer:double_tap_gesture];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([sender isKindOfClass:[LUSegment class]]) {
		LUSegment* segment = sender;
		LUSplitController* split_controller = [segue destinationViewController];
		split_controller.segment = segment;
	}
}

- (void) didDoubleTapCollectionView:(UITapGestureRecognizer *)gesture
{
	CGPoint pt = [gesture locationInView:self.collectionView];
	NSIndexPath* index_path = [self.collectionView indexPathForItemAtPoint:pt];
	[self editSegmentAtIndexPath:index_path];
}

- (void) editSegmentAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];

	LUSegment* segment = [[LUSegment alloc] init];
	segment.path = audio_path;
	segment.episode = self.episode;
	
	[self performSegueWithIdentifier:@"SplitSegue" sender:segment];
}

- (IBAction) onCancelRecord:(id)sender
{
	self.isInRecordMode = NO;

	self.playPauseButton.layer.cornerRadius = 0.0;
	self.playPauseButton.layer.backgroundColor = nil;

	[self.playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];

	[UIView animateWithDuration:0.3 animations:^
	{
		self.recordingDimView.alpha = 0.0;
	}];
}

- (IBAction) addAudio:(id)sender
{
	CGRect r = [self.view bounds];
	CGPoint pt = CGPointMake (r.size.width - 75, 80);
	
	self.addPopover = [PopoverView showPopoverAtPoint:pt inView:self.view withContentView:self.addPopoverView delegate:self];
}

- (IBAction) addMusic:(id)sender
{
	[self.addPopover dismiss];
	
	NSString* test_file = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"m4a" inDirectory:@"Music"];
	[self.episode addFile:test_file];
	[self.collectionView reloadData];
}

- (IBAction) addRecording:(id)sender
{
	self.isInRecordMode = YES;
	
	[self.addPopover dismiss];
	
	[UIView animateWithDuration:0.3 animations:^
	{
		self.recordingDimView.alpha = 1.0;
	}];

	self.playPauseButton.layer.cornerRadius = 28.0;
	self.playPauseButton.layer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5].CGColor;
	self.playPauseButton.clipsToBounds = YES;

	[self.playPauseButton setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
}

- (IBAction) publish:(id)sender
{
	[self performSegueWithIdentifier:@"PostSegue" sender:self];
}

- (IBAction) play:(id)sender
{
	// Handle recording a new clip...
	if (self.isInRecordMode)
	{
		if (!self.audioRecorder)
		{
			[self startRecording];
		}
		else
		{
			[self stopRecording];
		}
		return;
	}


	// Handle playing back the audio...
	if (self.player) {
		[self.player pause];
		self.player = nil;
	}
	else {
		AVMutableComposition* composition = [self makeComposition];
		
		AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:composition];
		[item addObserver:self forKeyPath:@"status" options:0 context:&kItemStatusContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];

		self.player = [AVPlayer playerWithPlayerItem:item];

		CMTime interval = CMTimeMakeWithSeconds (0.1, NSEC_PER_SEC);
		__weak LUEditController* weak_self = self;
		[self.player addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time) {
			dispatch_async (dispatch_get_main_queue(), ^{
				[weak_self updatePlayback:time];
			});
		}];

		[self.player play];
	}
	
	[self updatePlayButton];
}

- (void) startRecording
{
	NSURL* destination = [LUAudioRecorder generateTimeStampedFileURL];
	NSString* fileName = destination.path.lastPathComponent;
	destination = [[NSURL fileURLWithPath:self.episode.path] URLByAppendingPathComponent:fileName];
	self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:destination];
	self.timerLabel.hidden = NO;
	self.timerLabel.text = @"00:00";

	__weak LUEditController* weakSelf = self;
	self.audioRecorder.recordProgressCallback = ^(NSString* timeString)
	{
		weakSelf.timerLabel.text = timeString;
	};
	
	UIView* waveFormView = [self.audioRecorder requestAudioInputView];
	waveFormView.frame = self.waveFormViewContainer.bounds;
	[self.waveFormViewContainer addSubview:waveFormView];

	[self.audioRecorder record];
	self.waveFormViewContainer.hidden = NO;

	[self.playPauseButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
}

- (void) stopRecording
{
	self.waveFormViewContainer.hidden = YES;
	self.timerLabel.hidden = YES;
	
	// Remove the wave form...
	[[self.audioRecorder requestAudioInputView] removeFromSuperview];

	[self.audioRecorder stop];
	
	[self.episode addRecording:self.audioRecorder.destination.path];
	
	self.audioRecorder = nil;
	
	self.isInRecordMode = NO;

	self.playPauseButton.layer.cornerRadius = 0;
	self.playPauseButton.layer.backgroundColor = nil;

	[self.playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
	
	[UIView animateWithDuration:0.3 animations:^
	{
		self.recordingDimView.alpha = 0.0;
	}];
	
	[self.collectionView reloadData];
}

- (void) playerDidFinishPlaying:(NSNotification *)notification
{
	[self play:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &kItemStatusContext) {
		dispatch_async (dispatch_get_main_queue(), ^{
			// composition ready to play
		});
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) updatePlayback:(CMTime)time
{
//	AVPlayerItem* item = self.player.currentItem;
//	Float64 episode_duration = CMTimeGetSeconds (item.duration);
	Float64 episode_offset = CMTimeGetSeconds (time);
	Float64 current_offset = 0;

	for (NSInteger i = 0; i < self.episode.audioSegmentPaths.count; i++) {
		NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
		LUSegmentCell* cell = (LUSegmentCell *)[self.collectionView cellForItemAtIndexPath:index_path];

		NSString* path = [self.episode.audioSegmentPaths objectAtIndex:i];
		NSURL* url = [NSURL fileURLWithPath:path];
		AVAsset* asset = [AVAsset assetWithURL:url];
		Float64 segment_duration = CMTimeGetSeconds (asset.duration);
		if ((episode_offset > current_offset) && (episode_offset < (current_offset + segment_duration))) {
			Float64 segment_offset = episode_offset - current_offset;
			Float64 segment_progress = segment_offset / segment_duration;
			[cell updatePercentComplete:segment_progress];
		}
		else {
			[cell updatePercentComplete:0.0];
		}
		
		current_offset = current_offset + segment_duration;
	}
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

- (void) popoverViewDidDismiss:(PopoverView *)popoverView
{
}

- (CGSize) bestCellSize
{
	CGFloat w = (self.view.bounds.size.width / 2.0) - kCellPadding - (kCellPadding / 2.0);
	CGFloat h = 90.0;
	
	return CGSizeMake (w, h);
}

- (AVMutableComposition *) makeComposition
{
	AVMutableComposition* composition = [AVMutableComposition composition];
	AVMutableCompositionTrack* audio_track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

	CMTime offset = kCMTimeZero;
	for (NSString* audio_path in [self.episode audioSegmentPaths]) {
		AVAsset* asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audio_path]];
		AVAssetTrack* asset_track = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
		[audio_track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset_track.timeRange.duration) ofTrack:asset_track atTime:offset error:nil];
		offset = CMTimeAdd (offset, asset_track.timeRange.duration);
	}
	
	return composition;
}

- (void) exportCompositionToPath:(NSString *)path
{
	AVMutableComposition* composition = [self makeComposition];
	AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
	exporter.outputURL = [NSURL fileURLWithPath:path];
	exporter.outputFileType = AVFileTypeMPEGLayer3;
	[exporter exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			if (exporter.status == AVAssetExportSessionStatusCompleted) {
			}
		});
	}];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.episode audioSegmentPaths].count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	LUSegmentCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SegmentCell" forIndexPath:indexPath];
	
	//CGSize size = [self bestCellSize];
	
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];
	NSURL* audio_url = [NSURL fileURLWithPath:audio_path];
	
	LUAudioClip* audioData = [[LUAudioClip alloc] initWithDestination:audio_url];
	cell.previewImageView.image = audioData.waveFormImage;//[audioData renderWaveImage:size];
	
	cell.durationField.text = audioData.durationString;
	cell.previewImageView.layer.cornerRadius = 3.0;
	cell.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	cell.previewImageView.layer.borderWidth = 0.5;
	cell.positionLine.hidden = YES;
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	[self editSegmentAtIndexPath:indexPath];
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return [self bestCellSize];
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (kCellPadding, kCellPadding, kCellPadding, kCellPadding);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return kCellPadding;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return 0;
}

#pragma mark -

- (NSArray<UIDragItem *> *) collectionView:(UICollectionView *)collectionView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath
{
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];
	//NSURL* audio_url = [NSURL fileURLWithPath:audio_path isDirectory:NO];
	
	//EZAudioFile* audio_file = [EZAudioFile audioFileWithURL:audio_url];
	NSItemProvider* provider = [[NSItemProvider alloc] initWithObject:audio_path];

	UIDragItem* item = [[UIDragItem alloc] initWithItemProvider:provider];
	item.localObject = audio_path;
	
	return @[ item ];
}

- (UICollectionViewDropProposal *) collectionView:(UICollectionView *)collectionView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(nullable NSIndexPath *)destinationIndexPath
{
	UICollectionViewDropProposal* proposal;
	
	if (destinationIndexPath) {
		proposal = [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationMove intent:UICollectionViewDropIntentInsertAtDestinationIndexPath];
	}
	else {
		proposal = [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
	}
	
	return proposal;
}

- (void) collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(id<UICollectionViewDropCoordinator>)coordinator
{
	NSMutableArray* clips = [NSMutableArray arrayWithArray:self.episode.audioSegmentPaths];
	id<UICollectionViewDropItem> drop = [coordinator.items firstObject];

	NSIndexPath* endLocation = coordinator.destinationIndexPath;
	NSIndexPath* startLocation = drop.sourceIndexPath;
	NSString* clip = [clips objectAtIndex:startLocation.item];
	[clips removeObjectAtIndex:startLocation.item];
	[clips insertObject:clip atIndex:endLocation.item];
	
	[self.episode updateAudioSegmentOrder:clips];
	
	[self.collectionView performBatchUpdates:^
	{
		[self.collectionView deleteItemsAtIndexPaths:@[ startLocation ]];
		[self.collectionView insertItemsAtIndexPaths:@[ endLocation ]];
	}
	completion:^(BOOL finished)
	{
	}];
}

@end
