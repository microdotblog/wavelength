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
#import "LUPostController.h"
#import "LUExportController.h"
#import "LUNotifications.h"
#import <EZAudio/EZAudio.h>
#import "SSKeychain.h"

static CGFloat const kCellPadding = 10.0;
static const NSString* kItemStatusContext;

@interface LUEditController ()<UICollectionViewDragDelegate, UICollectionViewDropDelegate>
	@property (nonatomic, assign) BOOL isInRecordMode;
	@property (nonatomic, assign) BOOL isRecording;
	@property (nonatomic, strong) LUAudioRecorder* audioRecorder;
	@property (nonatomic, strong) IBOutlet UIView* waveFormViewContainer;
	@property (strong, nonatomic) IBOutlet NSLayoutConstraint* waveFormViewContainerBottomConstraint;
@end

@implementation LUEditController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNotifications];
	[self setupCollectionView];
	[self setupGestures];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replaceSegmentNotification:) name:kReplaceSegmentNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedExportNotification:) name:kFinishedExportNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(seekAudioSegmentNotification:) name:kSeekAudioSegmentNotification object:nil];
}

- (void) setupCollectionView
{
	self.collectionView.dragDelegate = self;
	self.collectionView.dropDelegate = self;
	self.collectionView.dragInteractionEnabled = YES;
	self.collectionView.allowsMultipleSelection = YES;
}

- (void) setupGestures
{
//	UITapGestureRecognizer* double_tap_gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapCollectionView:)];
//	double_tap_gesture.numberOfTapsRequired = 2;
//	[self.collectionView addGestureRecognizer:double_tap_gesture];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([sender isKindOfClass:[LUSegment class]]) {
		LUSegment* segment = sender;
		LUSplitController* split_controller = [segue destinationViewController];
		split_controller.segment = segment;
	}
	else if ([sender isKindOfClass:[LUEpisode class]]) {
		if ([segue.identifier isEqualToString:@"PostSegue"]) {
			LUEpisode* episode = sender;
			LUPostController* post_controller = [segue destinationViewController];
			post_controller.episode = episode;
		}
		else if ([segue.identifier isEqualToString:@"ExportSegue"]) {
			LUEpisode* episode = sender;
			LUExportController* export_controller = [segue destinationViewController];
			export_controller.episode = episode;
			export_controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		}
		else if ([segue.identifier isEqualToString:@"SigninSegue"]) {
		}
	}
}

- (void) replaceSegmentNotification:(NSNotification *)notification
{
	LUSegment* segment = [notification.userInfo objectForKey:kReplaceSegmentOriginalKey];
	NSArray* new_files = [notification.userInfo objectForKey:kReplaceSegmentNewArrayKey];
	[self.episode replaceFile:segment.path withFiles:new_files];
	[self.collectionView reloadData];
	
	for (NSString* selected_file in new_files) {
		for (NSInteger i = 0; i < self.episode.audioSegmentPaths.count; i++) {
			NSString* segment_file = [self.episode.audioSegmentPaths objectAtIndex:i];
			if ([segment_file isEqualToString:selected_file]) {
				NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
				[self.collectionView selectItemAtIndexPath:index_path animated:NO scrollPosition:UICollectionViewScrollPositionNone];
			}
		}
	}
}

- (void) finishedExportNotification:(NSNotification *)notification
{
	NSString* mp3_path = [notification.userInfo objectForKey:kFinishedExportFileKey];

	[self dismissViewControllerAnimated:YES completion:^{
		self.episode.exportedPath = mp3_path;
		[self performSegueWithIdentifier:@"PostSegue" sender:self.episode];
	}];
}

- (void) seekAudioSegmentNotification:(NSNotification *)notification
{
	NSString* audio_path = [notification.userInfo objectForKey:kSeekAudioSegmentFileKey];
	CGFloat fraction = [[notification.userInfo objectForKey:kSeekAudioSegmentPercent] floatValue];

	for (NSInteger i = 0; i < self.episode.audioSegmentPaths.count; i++) {
		NSString* segment_path = [self.episode.audioSegmentPaths objectAtIndex:i];
		if ([segment_path isEqualToString:audio_path]) {
			NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
			[self skipToSegmentAtIndexPath:index_path withinSegmentPercent:fraction];
			break;
		}
	}
}

- (void) didDoubleTapCollectionView:(UITapGestureRecognizer *)gesture
{
	CGPoint pt = [gesture locationInView:self.collectionView];
	NSIndexPath* index_path = [self.collectionView indexPathForItemAtPoint:pt];
	[self clearSelection];
	[self editSegmentAtIndexPath:index_path];
}

- (void) clearSelection
{
	NSArray* index_paths = self.collectionView.indexPathsForSelectedItems;
	if (index_paths) {
		for (NSIndexPath* index_path in index_paths) {
			[self.collectionView deselectItemAtIndexPath:index_path animated:NO];
		}
	}
}

- (void) editSegmentAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];

	LUSegment* segment = [[LUSegment alloc] init];
	segment.path = audio_path;
	segment.episode = self.episode;
	
	[self performSegueWithIdentifier:@"SplitSegue" sender:segment];
}

- (void) skipToSegmentAtIndexPath:(NSIndexPath *)indexPath withinSegmentPercent:(CGFloat)segmentFraction
{
	Float64 current_offset = 0;

	for (NSInteger i = 0; i < self.episode.audioSegmentPaths.count; i++) {
		NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];

		NSString* path = [self.episode.audioSegmentPaths objectAtIndex:i];
		NSURL* url = [NSURL fileURLWithPath:path];
		AVAsset* asset = [AVAsset assetWithURL:url];
		Float64 segment_duration = CMTimeGetSeconds (asset.duration);
		
		if ([index_path isEqual:indexPath]) {
			current_offset = current_offset + (segment_duration * segmentFraction);
			CMTime segment_offset = CMTimeMakeWithSeconds (current_offset, NSEC_PER_SEC);
			[self.player seekToTime:segment_offset];
			break;
		}

		current_offset = current_offset + segment_duration;
	}
}

- (IBAction) onCancelRecord:(id)sender
{
	self.isInRecordMode = NO;
	
	[UIView animateWithDuration:0.25 animations:^
	{
		self.waveFormViewContainerBottomConstraint.constant = -self.waveFormViewContainer.bounds.size.height;
		[self.view layoutIfNeeded];
	}
	completion:^(BOOL finished)
	{
		self.waveFormViewContainer.hidden = YES;
	}];

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
}

- (IBAction) publish:(id)sender
{
	NSString* token = [SSKeychain passwordForService:@"ExternalMicropub" account:@"default"];
	NSDictionary* userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"Micro.blog User Info"];
	
	if (!userInfo || !token)
	{
		[self performSegueWithIdentifier:@"SigninSegue" sender:self.episode];
	}
	else
	{
		self.episode.exportedPath = [self.episode.path stringByAppendingPathComponent:@"exported.m4a"];
		self.episode.exportedComposition = [self makeComposition];

		[self performSegueWithIdentifier:@"ExportSegue" sender:self.episode];		
	}
}

- (IBAction) play:(id)sender
{
	// Handle recording a new clip...
	if (self.isInRecordMode)
	{
		if (!self.isRecording)
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
	self.waveFormViewContainer.hidden = NO;

	self.waveFormViewContainerBottomConstraint.constant = -self.waveFormViewContainer.bounds.size.height;
	[self.view layoutIfNeeded];

	[UIView animateWithDuration:0.25 animations:^
	{
		self.waveFormViewContainerBottomConstraint.constant = 0.0;
		[self.view layoutIfNeeded];
	}];

	self.isRecording = YES;
	[self.audioRecorder record];

	[self.playPauseButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
}

- (void) stopRecording
{
	[UIView animateWithDuration:0.25 animations:^
	{
		self.waveFormViewContainerBottomConstraint.constant = -self.waveFormViewContainer.bounds.size.height;
		[self.view layoutIfNeeded];
	}
	completion:^(BOOL finished)
	{
		self.waveFormViewContainer.hidden = YES;
	}];


	self.isRecording = NO;
	
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
	CGFloat w = floor ((self.view.bounds.size.width / 2.0) - kCellPadding - (kCellPadding / 2.0));
	CGFloat h = 110.0;
	
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
	[cell setupWithFile:audio_path];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	[self clearSelection];
	if (self.player) {
		[self skipToSegmentAtIndexPath:indexPath withinSegmentPercent:0.0];
	}
	else {
		[self editSegmentAtIndexPath:indexPath];
	}
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	[self clearSelection];
	if (self.player) {
		[self skipToSegmentAtIndexPath:indexPath withinSegmentPercent:0.0];
	}
	else {
		[self editSegmentAtIndexPath:indexPath];
	}
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
