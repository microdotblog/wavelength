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
#import "LUAudioRecorder.h"
#import <EZAudio/EZAudio.h>

static CGFloat const kCellPadding = 10.0;

@interface LUEditController ()

@end

@implementation LUEditController

- (void) viewDidLoad
{
	[super viewDidLoad];
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
	
	EZAudioFile* audio_file = [EZAudioFile audioFileWithURL:audio_url];
	EZAudioFloatData* data = [audio_file getWaveformData];

	EZAudioPlot* plot = [[EZAudioPlot alloc] initWithFrame:CGRectMake (0, 0, size.width, size.height)];
	plot.shouldCenterYAxis = YES;
	plot.color = self.view.window.tintColor;

	[plot setSampleData:data.buffers[0] length:data.bufferSize];

	CALayer* layer = plot.waveformLayer;
	CGRect bounds = layer.bounds;
	layer.bounds = CGRectMake(0, 0, size.width, size.height);
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
	
    layer.bounds = bounds;

	cell.previewImageView.image = outputImage;
	
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

@end
