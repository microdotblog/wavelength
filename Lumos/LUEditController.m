//
//  LUEditController.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUEditController.h"

#import "LUEpisode.h"
#import "LUSegmentCell.h"
#import "LUAudioClip.h"
#import <EZAudio/EZAudio.h>

static CGFloat const kCellPadding = 10.0;
static const NSString* kItemStatusContext;

@interface LUEditController ()<UICollectionViewDragDelegate, UICollectionViewDropDelegate>

@end

@implementation LUEditController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.collectionView.dragDelegate = self;
	self.collectionView.dropDelegate = self;
	self.collectionView.dragInteractionEnabled = YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
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
}

- (IBAction) play:(id)sender
{
	if (self.player) {
		[self.player pause];
		self.player = nil;
	}
	else {
		AVMutableComposition* composition = [self makeComposition];
		
		AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:composition];
		[item addObserver:self forKeyPath:@"status" options:0 context:&kItemStatusContext];

//		CMTime interval = CMTimeMake (250, item.duration.timescale);
//		[self.player addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time) {
//			dispatch_async (dispatch_get_main_queue(), ^{
//			});
//		}];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];

		self.player = [AVPlayer playerWithPlayerItem:item];
		[self.player play];
	}
	
	[self updatePlayButton];
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
	
	CGSize size = [self bestCellSize];
	
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];
	NSURL* audio_url = [NSURL fileURLWithPath:audio_path isDirectory:NO];
	
	LUAudioClip* audioData = [[LUAudioClip alloc] initWithDestination:audio_url];
	cell.previewImageView.image = [audioData renderWaveImage:size];
	
	cell.previewImageView.layer.cornerRadius = 3.0;
	cell.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	cell.previewImageView.layer.borderWidth = 0.5;
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
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
