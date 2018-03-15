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
	
	NSString* audio_path = [[self.episode audioSegmentPaths] objectAtIndex:indexPath.item];
	NSURL* audio_url = [NSURL fileURLWithPath:audio_path isDirectory:NO];
	LUAudioRecorder* recorder = [[LUAudioRecorder alloc] initWithDestination:audio_url];

	cell.previewImageView.image = [recorder renderWaveImage:CGSizeMake (150, 90)];
	
	return cell;
}

@end
