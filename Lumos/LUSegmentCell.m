//
//  LUSegmentCell.m
//  Lumos
//
//  Created by Manton Reece on 3/15/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSegmentCell.h"

#import "LUSegment.h"
#import "LUAudioClip.h"
#import "LUNotifications.h"
#import "UUAlert.h"

@implementation LUSegmentCell

- (void) setupWithFile:(NSString *)path
{
	self.path = path;
	self.isEpisodePlaying = NO;
	
	NSURL* audio_url = [NSURL fileURLWithPath:path];
	LUAudioClip* clip = [[LUAudioClip alloc] initWithDestination:audio_url];
	
	self.previewImageView.image = clip.waveFormImage; // [clip renderWaveImage:size];
	
	self.durationField.text = clip.durationString;
	self.previewImageView.layer.cornerRadius = 3.0;
	self.previewImageView.layer.borderColor = [UIColor colorNamed:@"color_segment_border"].CGColor;
	self.previewImageView.layer.borderWidth = 0.5;
	self.positionLine.hidden = YES;

	self.deleteButton.layer.cornerRadius = self.deleteButton.bounds.size.width / 2.0;
	self.deleteButton.layer.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
	self.deleteButton.clipsToBounds = YES;

	[self setupGesture];
}

- (void) setupGesture
{
	self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
}

- (void) setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	if (selected) {
		self.previewImageView.layer.borderColor = [UIColor blackColor].CGColor;
		self.backgroundColor = [UIColor colorNamed:@"color_segment_selected"];
		self.deleteButton.hidden = NO;
	}
	else {
		self.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
		self.backgroundColor = nil;
		self.deleteButton.hidden = YES;
	}
}

- (IBAction) delete:(id)sender
{
	LUSegment* segment = [[LUSegment alloc] init];
	segment.path = self.path;
	segment.episode = nil;

	[UUAlertViewController uuShowTwoButtonAlert:nil message:@"Are you sure you want to delete this segment?" buttonOne:@"Cancel" buttonTwo:@"Delete" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kReplaceSegmentNotification object:self userInfo:@{
				kReplaceSegmentOriginalKey: segment,
				kReplaceSegmentNewArrayKey: @[]
			}];
		}
	}];
}

- (void) pan:(UIPanGestureRecognizer *)gesture
{
	if (self.isEpisodePlaying) {
		CGPoint pt = [gesture locationInView:self];
		CGFloat fraction = pt.x / self.bounds.size.width;
		[self updatePercentComplete:fraction];
		
		if (gesture.state == UIGestureRecognizerStateEnded) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kSeekAudioSegmentNotification object:self userInfo:@{
				kSeekAudioSegmentFileKey: self.path,
				kSeekAudioSegmentPercent: @(fraction)
			}];
		}
	}
}

- (void) updatePercentComplete:(CGFloat)value
{
	if (value == 0.0) {
		self.positionLine.hidden = YES;
	}
	else {
		CGFloat x = self.bounds.size.width * value;
		CGRect r = self.positionLine.frame;
		r.origin.x = x;
		self.positionLine.frame = r;
		self.positionLine.hidden = NO;
	}
}

- (void) setPlaying:(BOOL)isPlaying
{
	self.isEpisodePlaying = isPlaying;
	
	if (self.isEpisodePlaying) {
		[self addGestureRecognizer:self.panGesture];
	}
	else {
		[self removeGestureRecognizer:self.panGesture];
	}
}

@end
