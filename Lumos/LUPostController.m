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
	
	[self.titleField becomeFirstResponder];
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

- (IBAction) playOrPause:(id)sender
{
}

@end
