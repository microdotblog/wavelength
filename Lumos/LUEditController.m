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
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.episode audioSegmentPaths].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	LUSegmentCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SegmentCell" forIndexPath:indexPath];
	
	CGSize size = CGSizeMake (150, 90);
	
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];
	NSURL* audio_url = [NSURL fileURLWithPath:audio_path isDirectory:NO];
	
	EZAudioFile* audio_file = [EZAudioFile audioFileWithURL:audio_url];
	EZAudioFloatData* data = [audio_file getWaveformData];
	EZAudioPlot* plot = [[EZAudioPlot alloc] initWithFrame:CGRectMake (0, 0, size.width, size.height)];
	plot.shouldCenterYAxis = YES;
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
	
	return cell;
}

@end
