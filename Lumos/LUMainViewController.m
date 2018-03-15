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
#import "LUEditController.h"

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
	
	[self setupEpisodes];
	[self setupAudio];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self.audioRecorder requestAudioInputView].frame = self.waveFormViewContainer.bounds;
}

- (void) setupAudio
{
    NSURL* path = [LUAudioRecorder generateTimeStampedFileURL];
	
    self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:path];

	__weak LUMainViewController* weakSelf = self;
    self.audioRecorder.playbackCompleteCallback = ^(LUAudioRecorder* audioRecorder)
    {
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[weakSelf.recordStopPlayButton setTitle:@"Record" forState:UIControlStateNormal];
		});
	};
	
	UIView* waveFormView = [self.audioRecorder requestAudioInputView];
	waveFormView.frame = self.waveFormViewContainer.bounds;
	[self.waveFormViewContainer addSubview:waveFormView];
}

- (void) setupEpisodes
{
	self.episodes = [NSMutableArray array];

	NSURL* documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
;
	NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsDirectory includingPropertiesForKeys:nil options:0 error:NULL];
	for (NSURL* url in contents) {
		BOOL is_dir = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&is_dir];
		if (is_dir) {
			LUEpisode* episode = [[LUEpisode alloc] initWithFolder:url.path];
			[self.episodes addObject:episode];
		}
	}
}

- (IBAction) onRecord:(id)sender
{
	if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Record"])
	{
		self.waveFormViewContainer.hidden = NO;
		[self.recordStopPlayButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.audioRecorder record];
	}
	else if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Stop"])
	{
		self.waveFormViewContainer.hidden = YES;
		[self.recordStopPlayButton setTitle:@"Record" forState:UIControlStateNormal];
		[self.audioRecorder stop];
		
		CGSize preview_size = CGSizeMake (150, 54);
		
		LUEpisode* episode = [[LUEpisode alloc] init];
		episode.previewImage = [self.audioRecorder renderWaveImage:preview_size];
		episode.path = [self.audioRecorder.destination URLByDeletingLastPathComponent].path;
		episode.title = [episode.path lastPathComponent];

		NSData* d = UIImagePNGRepresentation (episode.previewImage);
		NSString* preview_filepath = [episode.path stringByAppendingPathComponent:@"preview.png"];
		[d writeToFile:preview_filepath atomically:NO];
		
		[self.episodes addObject:episode];

		[self.tableView reloadData];
	}
	else if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Play"])
	{
		[self.recordStopPlayButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.audioRecorder play];
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	LUEpisode* episode = sender;
    LUEditController* edit_controller =  [segue destinationViewController];
	edit_controller.episode = episode;
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
	[cell setupWithEpisode:episode];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	LUEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
	[self performSegueWithIdentifier:@"EditSegue" sender:episode];
}

@end
