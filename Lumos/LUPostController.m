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

- (void) setupWaveform
{
	LUAudioClip* clip = [[LUAudioClip alloc] initWithDestination:self.episode.exportedPath];
	UIView* v = [clip requestAudioInputView];
	v.frame = self.waveformView.bounds;
	[self.waveformView addSubview:v];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
