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
#import "RFClient.h"
#import "UUAlert.h"

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
	if (@available(iOS 13.0, *)) {
		self.titleContainer.layer.borderColor = [UIColor separatorColor].CGColor;
		self.titleContainer.layer.borderWidth = 0.5;
	}

	NSString* blog_name = [[NSUserDefaults standardUserDefaults] objectForKey:@"Wavelength:blog:name"];
	self.hostnameField.text = blog_name;
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) setupWaveform
{
	if (self.waveformView.subviews.count == 0) {
		NSURL* url = [NSURL fileURLWithPath:self.episode.exportedPath];
		LUAudioClip* clip = [[LUAudioClip alloc] initWithDestination:url];
		UIView* v = [clip requestAudioInputView];
		v.frame = self.waveformView.bounds;
		[self.waveformView addSubview:v];
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark -

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

#pragma mark -

- (IBAction) post:(id)sender
{
	if (self.isPosting) {
		return;
	}
	
	self.isPosting = YES;
	[self.progressSpinner startAnimating];
	
	NSString* blog_uid = [[NSUserDefaults standardUserDefaults] objectForKey:@"Wavelength:blog:uid"];

	NSData* d = [NSData dataWithContentsOfFile:self.episode.exportedPath];
	NSDictionary* args = @{
		@"mp-destination": blog_uid
	};
	
	NSString* title = self.titleField.text;
	NSString* text = self.textView.text;
	
	if (title.length > 0) {
		self.episode.title = title;
		[self.episode saveFileInfo];
	}
		
	if (text.length == 0) {
		self.isPosting = NO;
		[self.progressSpinner stopAnimating];
		[UUAlertViewController uuShowOneButtonAlert:@"Missing Post Text" message:@"The post text should not be blank. This text will be used for the show notes for your microcast." button:@"OK" completionHandler:NULL];
		return;
	}

	if (d.length == 0) {
		self.isPosting = NO;
		[self.progressSpinner stopAnimating];
		[UUAlertViewController uuShowOneButtonAlert:@"Missing Audio Data" message:@"The episode audio file is not valid." button:@"OK" completionHandler:NULL];
		return;
	}

	NSInteger max_upload_filesize = 1024 * 1024 * 45; // 45 MB
	if (d.length > max_upload_filesize) {
		self.isPosting = NO;
		[self.progressSpinner stopAnimating];
		[UUAlertViewController uuShowOneButtonAlert:@"Audio Size Limit" message:@"Your microcast episodes can be a few minutes up to 30 minutes. There is a 45 MB upload size limit." button:@"OK" completionHandler:NULL];
		return;
	}
	
	RFClient* media_client = [[RFClient alloc] initWithPath:@"/micropub/media"];
	[media_client uploadAudioData:d named:@"file" fileExtension:@"mp3" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
		if (response.httpResponse.statusCode >= 200 && response.httpResponse.statusCode < 300) {
			NSString* audio_url = [response.httpResponse.allHeaderFields objectForKey:@"Location"];
			NSDictionary* params = @{
				@"name": title,
				@"content": text,
				@"audio": audio_url,
				@"mp-destination": blog_uid
			};
			RFClient* post_client = [[RFClient alloc] initWithPath:@"/micropub"];
			[post_client postWithParams:params completion:^(UUHttpResponse* response) {
    			dispatch_async (dispatch_get_main_queue(), ^{
    				if (response.httpError) {
						self.isPosting = NO;
						[self.progressSpinner stopAnimating];
						NSString* msg = nil;
						if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
							msg = [response.parsedResponse objectForKey:@"error_description"];
						}
						
						if (msg == nil) {
							msg = [response.httpError localizedDescription];
						}
						
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:msg button:@"OK" completionHandler:NULL];
    				}
    				else {
						[self.navigationController popViewControllerAnimated:YES];
					}
				});
			}];
		}
		else {
    		dispatch_async (dispatch_get_main_queue(), ^{
				self.isPosting = NO;
				[self.progressSpinner stopAnimating];
				NSString* msg = [response.httpError localizedDescription];
				[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Audio" message:msg button:@"OK" completionHandler:NULL];
			});
		}
	}];
}

- (IBAction) playOrPause:(id)sender
{
	if (self.player) {
		[self.player pause];
		self.player = nil;
	}
	else {
		self.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:self.episode.exportedPath]];

		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];

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
	CGFloat fraction = 0.0;
	if ((offset > 0.0) && (duration > 0.0)) {
		fraction = offset / duration;
	}

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
		img = [UIImage imageNamed:@"pause_noborder"];
	}
	else {
		img = [UIImage imageNamed:@"play_noborder"];
		self.positionLine.hidden = YES;
	}

	[self.playPauseButton setImage:img forState:UIControlStateNormal];
}

@end
