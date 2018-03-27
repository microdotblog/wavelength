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
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
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

	CGRect container_r = CGRectMake ([self bestPadding], 50, size.width, size.height - 100);
	CGRect audio_r = CGRectMake (0, 0, size.width, size.height - 100);

	UIView* v = [clip requestAudioInputView];
	v.frame = audio_r;

	UIView* container = [[UIView alloc] initWithFrame:container_r];
	container.layer.shadowColor = [UIColor lightGrayColor].CGColor;
	container.layer.shadowOpacity = 0.5;
	container.layer.shadowRadius = 3.0;
	container.layer.shadowOffset = CGSizeMake (0, 0);
	container.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:container.bounds cornerRadius:7.0].CGPath;
	container.layer.backgroundColor = [UIColor whiteColor].CGColor;
	container.layer.cornerRadius = 7.0;
	[container addSubview:v];
	
	[self.scrollView addSubview:container];
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
