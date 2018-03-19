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

- (void) popoverViewDidDismiss:(PopoverView *)popoverView
{
}

- (CGSize) bestCellSize
{
	CGFloat w = (self.view.bounds.size.width / 2.0) - kCellPadding - (kCellPadding / 2.0);
	CGFloat h = 90.0;
	
	return CGSizeMake (w, h);
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

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return [self bestCellSize];
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (kCellPadding, kCellPadding, kCellPadding, kCellPadding);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return kCellPadding;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
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
