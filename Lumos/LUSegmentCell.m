//
//  LUSegmentCell.m
//  Lumos
//
//  Created by Manton Reece on 3/15/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSegmentCell.h"

#import "LUAudioClip.h"
#import "LUNotifications.h"

@implementation LUSegmentCell

- (void) setupWithFile:(NSString *)path
{
	self.path = path;
	
	NSURL* audio_url = [NSURL fileURLWithPath:path];
	LUAudioClip* clip = [[LUAudioClip alloc] initWithDestination:audio_url];
	
	self.previewImageView.image = clip.waveFormImage; // [clip renderWaveImage:size];
	
	self.durationField.text = clip.durationString;
	self.previewImageView.layer.cornerRadius = 3.0;
	self.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	self.previewImageView.layer.borderWidth = 0.5;
	self.positionLine.hidden = YES;

	self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	[self addGestureRecognizer:self.panGesture];
}

- (void) setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	if (selected) {
		self.previewImageView.layer.borderColor = [UIColor blackColor].CGColor;
		self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
	}
	else {
		self.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
		self.backgroundColor = nil;
	}
}

- (void) pan:(UIPanGestureRecognizer *)gesture
{
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

@end
