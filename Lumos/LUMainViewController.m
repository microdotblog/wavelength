//
//  LUMainViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/12/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUMainViewController.h"
#import "LUAudioRecorder.h"

@interface LUMainViewController ()
	@property (nonatomic, strong) LUAudioRecorder* audioRecorder;
	@property (nonatomic, strong) IBOutlet UIButton* recordStopPlayButton;
@end

@implementation LUMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL* path = [LUAudioRecorder generateTimeStampedFileURL];
	
    self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:path];

	__weak LUMainViewController* weakSelf = self;
    self.audioRecorder.playbackCompleteCallback = ^(LUAudioRecorder* audioRecorder)
    {
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[weakSelf.recordStopPlayButton setTitle:@"Play" forState:UIControlStateNormal];
		});
	};
}

- (IBAction) onRecord:(id)sender
{
	if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Record"])
	{
		[self.recordStopPlayButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.audioRecorder record];
	}
	else if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Stop"])
	{
		[self.recordStopPlayButton setTitle:@"Play" forState:UIControlStateNormal];
		[self.audioRecorder stop];
	}
	else if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Play"])
	{
		[self.recordStopPlayButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.audioRecorder play];
	}
}


@end
