//
//  LUMainViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/12/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUMainViewController.h"

#import "LUAudioRecorder.h"
#import "LUAudioClip.h"
#import "LUEpisode.h"
#import "LUEpisodeCell.h"
#import "LUEditController.h"

@interface LUMainViewController ()
	@property (nonatomic, strong) IBOutlet UIButton* recordStopPlayButton;
	@property (nonatomic, strong) IBOutlet UIView* waveFormViewContainer;
	@property (nonatomic, strong) IBOutlet UITableView* tableView;

	@property (nonatomic, strong) LUAudioRecorder* audioRecorder;
	@property (nonatomic, strong) NSMutableArray* episodes; // LUEpisode
	@property (nonatomic, assign) BOOL isRecording;
@end

@implementation LUMainViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	[self setupEpisodes];
	
	[self updateRecordButton];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
}

- (void) setupAudio
{
	if (self.audioRecorder == nil) {
		NSURL* path = [LUAudioRecorder generateTimeStampedFileURL];
		self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:path];

		/*
		__weak LUMainViewController* weakSelf = self;
		self.audioRecorder.playbackCompleteCallback = ^(LUAudioClip* audioRecorder)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				weakSelf.isRecording = NO;
				[weakSelf updateRecordButton];
			});
		};
		*/
		
		UIView* waveFormView = [self.audioRecorder requestAudioInputView];
		waveFormView.frame = self.waveFormViewContainer.bounds;
		[self.waveFormViewContainer addSubview:waveFormView];

		[self.audioRecorder requestAudioInputView].frame = self.waveFormViewContainer.bounds;
	}
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
			
			if (episode)
			{
				[self.episodes addObject:episode];
			}
		}
	}
}

- (void) updateRecordButton
{
	self.recordStopPlayButton.layer.cornerRadius = 28.0;
	self.recordStopPlayButton.layer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5].CGColor;
	self.recordStopPlayButton.clipsToBounds = YES;
	
	UIImage* img;
	if (self.isRecording) {
		img = [UIImage imageNamed:@"stop"];
	}
	else {
		img = [UIImage imageNamed:@"mic"];
	}
	[self.recordStopPlayButton setImage:img forState:UIControlStateNormal];
}

- (IBAction) onRecord:(id)sender
{
	[self setupAudio];

	if (!self.isRecording)
	{
		self.isRecording = YES;
		[self updateRecordButton];

		self.waveFormViewContainer.hidden = NO;
		[self.audioRecorder record];
	}
	else
	{
		self.isRecording = NO;
		[self updateRecordButton];
		
		[self.audioRecorder stop];

		self.waveFormViewContainer.hidden = YES;
		//[self.audioRecorder stop];
		
		CGSize preview_size = CGSizeMake (150, 54);
		
		NSString* episodePath = [self.audioRecorder.destination URLByDeletingLastPathComponent].path;

		UIImage* previewImage = [self.audioRecorder renderWaveImage:preview_size];
		NSData* d = UIImagePNGRepresentation(previewImage);
		NSString* preview_filepath = [episodePath stringByAppendingPathComponent:@"preview.png"];
		[d writeToFile:preview_filepath atomically:NO];

		LUEpisode* episode = [[LUEpisode alloc] initWithFolder:episodePath];
		episode.previewImage = previewImage;
		
		[self.episodes addObject:episode];
		
		[self.tableView reloadData];
		[self performSegueWithIdentifier:@"EditSegue" sender:episode];
	}

//	else if ([[self.recordStopPlayButton titleForState:UIControlStateNormal] isEqualToString:@"Play"])
//	{
//		[self.recordStopPlayButton setTitle:@"Stop" forState:UIControlStateNormal];
//		[self.audioRecorder play];
//	}
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

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: prompt to confirm deletion
	// ...
	
	LUEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
	[[NSFileManager defaultManager] removeItemAtPath:episode.path error:NULL];
	[self setupEpisodes];
	
	[self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
}

@end
