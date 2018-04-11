//
//  LUMainViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/12/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUViewController.h"
#import "LUMainViewController.h"
#import "LUNotifications.h"
#import "LUAudioRecorder.h"
#import "LUAudioClip.h"
#import "LUEpisode.h"
#import "LUEpisodeCell.h"
#import "LUEditController.h"
#import "LUSettingsViewController.h"
#import "UUAlert.h"

@interface LUMainViewController ()
	@property (nonatomic, strong) IBOutlet UIButton* recordStopPlayButton;
	@property (nonatomic, strong) IBOutlet UIView* waveFormViewContainer;
	@property (nonatomic, strong) IBOutlet UITableView* tableView;
	@property (strong, nonatomic) IBOutlet UILabel* _Nonnull timerLabel;
	@property (strong, nonatomic) IBOutlet NSLayoutConstraint* waveFormViewContainerBottomConstraint;
	@property (strong, nonatomic) IBOutlet UILabel* recordDeviceField;

	@property (nonatomic, strong) LUAudioRecorder* audioRecorder;
	@property (nonatomic, strong) NSMutableArray* episodes; // LUEpisode
	@property (nonatomic, assign) BOOL isRecording;
	@property (nonatomic, assign) BOOL isRecordingRecentlyStarted;
@end

@implementation LUMainViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	[self setupEpisodes];
	
	[self updateRecordButton];
	
	[self setupAudio];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self setupEpisodes];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRecordingDeviceChangedNotification:) name:kRecordingDeviceChangedNotification object:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRecordingDeviceChangedNotification object:nil];
}

- (void) handleRecordingDeviceChangedNotification:(NSNotification*)notification
{
	if (self.isRecording)
	{
		[self onRecord:self];
	}
	else
	{
		if (self.audioRecorder)
		{
			UIView* waveFormView = [self.audioRecorder requestAudioInputView];
			[waveFormView removeFromSuperview];
		}
		
		self.audioRecorder = nil;
		[self setupAudio];
	}
}

- (void) setupAudio
{
	if (self.audioRecorder == nil) {
//		NSURL* path = [LUAudioRecorder generateTimeStampedFileURL];
		self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:nil];
		
		__weak LUMainViewController* weakSelf = self;
		self.audioRecorder.recordProgressCallback = ^(NSString* timeString)
		{
			weakSelf.timerLabel.text = timeString;
		};
		
		UIView* waveFormView = [self.audioRecorder requestAudioInputView];
		waveFormView.frame = self.waveFormViewContainer.bounds;
		[self.waveFormViewContainer addSubview:waveFormView];

		[self.audioRecorder requestAudioInputView].frame = self.waveFormViewContainer.bounds;
	}

	if (self.audioRecorder.customDeviceName) {
		self.recordDeviceField.text = self.audioRecorder.customDeviceName;
	}
	else {
		self.recordDeviceField.text = @"";
	}
}

- (void) setupEpisodes
{
	self.episodes = [NSMutableArray array];

	NSURL* documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

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
	
	[self.episodes sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
	{
		LUEpisode* episode1 = obj1;
		LUEpisode* episode2 = obj2;
		
		return [episode2.path compare:episode1.path];
	}];
	
	[self.tableView reloadData];
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
	if (self.isRecordingRecentlyStarted) {
		return;
	}

	[self setupAudio];

	if (!self.isRecording)
	{
		NSURL* path = [LUAudioRecorder generateTimeStampedFileURL];
		self.audioRecorder.destination = path;

		self.isRecordingRecentlyStarted = YES;
		dispatch_after (dispatch_time (DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			self.isRecordingRecentlyStarted = NO;
		});

		self.waveFormViewContainerBottomConstraint.constant = -self.waveFormViewContainer.bounds.size.height;
		[self.view layoutIfNeeded];

		[UIView animateWithDuration:0.25 animations:^
		{
			self.waveFormViewContainerBottomConstraint.constant = 0.0;
			[self.view layoutIfNeeded];
		}];
		
		self.waveFormViewContainer.hidden = NO;
		self.timerLabel.hidden = NO;
		self.timerLabel.text = @"00:00";
		
		self.isRecording = YES;
		[self updateRecordButton];

		self.waveFormViewContainer.hidden = NO;
		[self.audioRecorder record];
	}
	else
	{
		self.timerLabel.hidden = YES;
		self.waveFormViewContainer.hidden = YES;

		self.isRecording = NO;
		[self updateRecordButton];
		
		[self.audioRecorder stop];

		//self.waveFormViewContainer.hidden = YES;
		//[self.audioRecorder stop];
		
		CGSize preview_size = CGSizeMake (150, 54);
		
		NSString* episodePath = [self.audioRecorder.destination URLByDeletingLastPathComponent].path;

		UIImage* previewImage = [self.audioRecorder renderWaveImage:preview_size];
		NSData* d = UIImagePNGRepresentation(previewImage);
		NSString* preview_filepath = [episodePath stringByAppendingPathComponent:@"preview.png"];
		[d writeToFile:preview_filepath atomically:NO];
		
		NSString* thumbnail_filepath = self.audioRecorder.destination.path;
		thumbnail_filepath = [thumbnail_filepath stringByAppendingString:@"-thumbnail.png"];
		[d writeToFile:thumbnail_filepath atomically:NO];

		LUEpisode* episode = [[LUEpisode alloc] initWithFolder:episodePath];
		episode.previewImage = previewImage;
		
		[self.episodes addObject:episode];
		
		[self.episodes sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
		{
			LUEpisode* episode1 = obj1;
			LUEpisode* episode2 = obj2;
		
			return [episode2.path compare:episode1.path];
		}];

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
	UIViewController* destinationController = segue.destinationViewController;
	
	if ([destinationController isKindOfClass:[LUEditController class]])
	{
		LUEpisode* episode = sender;
    	LUEditController* edit_controller = [segue destinationViewController];
		edit_controller.episode = episode;
	}
	else if ([destinationController isKindOfClass:[LUSettingsViewController class]])
	{
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
	[UUAlertViewController uuShowTwoButtonAlert:nil message:@"Are you sure you want to delete this episode?" buttonOne:@"Cancel" buttonTwo:@"Delete" completionHandler:^(NSInteger buttonIndex)
	{
		if (buttonIndex == 1)
		{
			LUEpisode* episode = [self.episodes objectAtIndex:indexPath.row];
			[[NSFileManager defaultManager] removeItemAtPath:episode.path error:NULL];
			[self setupEpisodes];
	
			//[self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
		}
	}];
	
}

@end
