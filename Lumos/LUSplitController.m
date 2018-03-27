//
//  LUSplitController.m
//  Lumos
//
//  Created by Manton Reece on 3/20/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSplitController.h"

#import "LUSegment.h"
#import "LUAudioClip.h"

@implementation LUSplitController

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupButtons];
	[self setupGraph];
}

- (void) setupButtons
{
	self.splitButton.layer.cornerRadius = 28.0;
	self.splitButton.layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
	self.splitButton.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1.0].CGColor;
	self.splitButton.layer.borderWidth = 1.0;
	self.splitButton.clipsToBounds = YES;
}

- (void) setupGraph
{
	NSURL* audio_url = [NSURL fileURLWithPath:self.segment.path];
	LUAudioClip* clip = [[LUAudioClip alloc] initWithDestination:audio_url];

	CGFloat w = [self bestWidthForDuration:clip.duration];
	CGSize size = CGSizeMake (w, self.scrollView.bounds.size.height);
	UIView* v = [clip requestAudioInputView];
	v.frame = CGRectMake ([self bestPadding], 0, size.width, size.height);
	[self.scrollView addSubview:v];
	[self.scrollView setContentSize:CGSizeMake (size.width + ([self bestPadding] * 2), size.height)];
}

- (CGFloat) bestWidthForDuration:(NSTimeInterval)duration
{
	// 300 pixels wide per second of audio
	return 300.0 * duration;
}

- (CGFloat) bestPadding
{
	return self.view.bounds.size.width / 2.0;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
}

- (IBAction) play:(id)sender
{
}

- (IBAction) split:(id)sender
{
}

- (IBAction) delete:(id)sender
{
}

@end
