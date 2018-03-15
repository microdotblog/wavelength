//
//  LUMainViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/12/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUMainViewController.h"

#import "LUAudioRecorder.h"
#import "LUEpisode.h"
#import "LUEpisodeCell.h"

@interface LUMainViewController ()
	@property (nonatomic, strong) IBOutlet UIButton* recordStopPlayButton;
	@property (nonatomic, strong) IBOutlet UIView* waveFormViewContainer;
	@property (nonatomic, strong) IBOutlet UITableView* tableView;

	@property (nonatomic, strong) LUAudioRecorder* audioRecorder;
	@property (nonatomic, strong) NSMutableArray* episodes; // LUEpisode
@end

@implementation LUMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL* path = [LUAudioRecorder generateTimeStampedFileURL];
	
	self.episodes = [NSMutableArray array];
    self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:path];

	__weak LUMainViewController* weakSelf = self;
    self.audioRecorder.playbackCompleteCallback = ^(LUAudioRecorder* audioRecorder)
    {
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[weakSelf.recordStopPlayButton setTitle:@"Play" forState:UIControlStateNormal];
		});
	};
	
	UIView* waveFormView = [self.audioRecorder requestAudioInputView];
	waveFormView.frame = self.waveFormViewContainer.bounds;
	[self.waveFormViewContainer addSubview:waveFormView];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self.audioRecorder requestAudioInputView].frame = self.waveFormViewContainer.bounds;
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
		
		CGRect r = self.tableView.bounds;
		r.size.height = 60;
		
		LUEpisode* episode = [[LUEpisode alloc] init];
		episode.title = [self.audioRecorder.destination.pathComponents lastObject];
		episode.previewImage = [self.audioRecorder renderWaveImage:r.size];
		
		[self.episodes addObject:episode];

		[self.tableView reloadData];
	}
	else if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Play"])
	{
		[self.recordStopPlayButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.audioRecorder play];
	}
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.episodes.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LUEpisodeCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"EpisodeCell"];
	
	LUEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
	cell.titleField.text = episode.title;
	cell.previewImageView.image = episode.previewImage;
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self performSegueWithIdentifier:@"EditSegue" sender:self];
}

@end
