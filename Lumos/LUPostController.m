//
//  LUPostController.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUPostController.h"

#import "LUAudioClip.h"
#import "LUEpisode.h"

@implementation LUPostController

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupFields];
	[self setupNotifications];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.textView becomeFirstResponder];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self setupWaveform];
}

- (void) setupFields
{
	self.titleContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
	self.titleContainer.layer.borderWidth = 0.5;
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) setupWaveform
{
	NSURL* url = [NSURL fileURLWithPath:self.episode.exportedPath];
	LUAudioClip* clip = [[LUAudioClip alloc] initWithDestination:url];
	UIView* v = [clip requestAudioInputView];
	v.frame = self.waveformView.bounds;
	[self.waveformView addSubview:v];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void) keyboardWillShowNotification:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect kb_r = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat kb_bottom = self.view.bounds.size.height - kb_r.origin.y;
	[UIView animateWithDuration:0.3 animations:^{
		self.bottomConstraint.constant = kb_bottom;
		[self.view layoutIfNeeded];
	}];
}

- (void) keyboardWillHideNotification:(NSNotification*)aNotification
{
	[UIView animateWithDuration:0.3 animations:^{
		self.bottomConstraint.constant = 0;
		[self.view layoutIfNeeded];
	}];
}

- (void) playerDidFinishPlaying:(NSNotification *)notification
{
	[self playOrPause:nil];
}

- (IBAction) playOrPause:(id)sender
{
	if (self.player) {
		[self.player pause];
		self.player = nil;
	}
	else {
		self.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:self.episode.exportedPath]];

		AVPlayerItem* item = self.player.currentItem;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];

		CMTime interval = CMTimeMakeWithSeconds (0.05, NSEC_PER_SEC);
		__weak LUPostController* weak_self = self;
		[self.player addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time) {
			dispatch_async (dispatch_get_main_queue(), ^{
				[weak_self updatePlayback:time];
			});
		}];

		[self.player play];
	}
	
	[self updatePlayButton];
}

- (void) updatePlayback:(CMTime)time
{
	if (self.player == nil) {
		self.positionLine.hidden = YES;
		return;
	}
	
	Float64 offset = CMTimeGetSeconds (time);
	Float64 duration = CMTimeGetSeconds (self.player.currentItem.duration);
	CGFloat w = self.waveformView.bounds.size.width;
	CGFloat fraction = offset / duration;

	if (fraction == 0.0) {
		self.positionLine.hidden = YES;
	}
	else {
		CGRect bar_frame = self.waveformView.frame;
		CGFloat x = fraction * w;
		CGRect r = self.positionLine.frame;
		r.origin.x = bar_frame.origin.x + x;
		self.positionLine.frame = r;
		self.positionLine.hidden = NO;
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

@end
