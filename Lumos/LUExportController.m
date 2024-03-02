//
//  LUExportController.m
//  Wavelength
//
//  Created by Manton Reece on 3/31/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUExportController.h"

#import "LUEpisode.h"
#import "LUNotifications.h"
#import "LUAuphonic.h"
#import "UUAlert.h"
#import <AVFoundation/AVFoundation.h>

static NSString* const kAuphonicProductionTimerKey = @"production_uuid";

@implementation LUExportController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.messageField.text = @"Preparing episode...";
	self.subtitleField.text = @"Combining audio segments.";
	self.containerView.layer.cornerRadius = 10.0;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.episode exportWithCompletion:^{
		NSString* auphonic_username = [LUAuphonic savedUsername];
		if (auphonic_username) {
			self.messageField.text = @"Uploading to Auphonic...";
			self.subtitleField.text = @"Creating Auphonic production.";
			LUAuphonic* client = [[LUAuphonic alloc] init];
			[client createProductionWithCompletion:^(NSString* productionUUID, NSError* error) {
				if (self.isCancelled) {
					[self dismissViewControllerAnimated:YES completion:NULL];
				}
				else if (error) {
					[self showError:error];
				}
				else {
					self.messageField.text = @"Uploading to Auphonic...";
					self.subtitleField.text = @"Sending audio data.";
					NSData* d = [NSData dataWithContentsOfFile:self.episode.exportedPath];
					[client sendAudio:d toProduction:productionUUID withCompletion:^(NSError* error) {
						if (self.isCancelled) {
							[self dismissViewControllerAnimated:YES completion:NULL];
						}
						else if (error) {
							[self showError:error];
						}
						else {
							self.messageField.text = @"Waiting on Auphonic...";
							self.subtitleField.text = @"This may take a few minutes.";
							[client startProduction:productionUUID withCompletion:^(NSError *error) {
								if (self.isCancelled) {
									[self dismissViewControllerAnimated:YES completion:NULL];
								}
								else if (error) {
									[self showError:error];
								}
								else {
									self.checkProductionTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkProductionFromTimer:) userInfo:@{ kAuphonicProductionTimerKey: productionUUID } repeats:NO];
									[self checkProduction:productionUUID];
								}
							}];
						}
					}];
				}
			}];
		}
		else {
			self.messageField.text = @"Preparing episode...";
			self.subtitleField.text = @"Converting to MP3 format.";
			[self convertToMP3];
		}
	}];
}

- (IBAction) cancel:(id)sender
{
	self.isCancelled = YES;
	if (self.checkProductionTimer) {
		[self.checkProductionTimer invalidate];
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

#pragma mark -

- (void) showError:(NSError *)error
{
	NSString* msg = [error localizedDescription];
	[UUAlertViewController uuShowOneButtonAlert:@"Error Exporting Audio" message:msg button:@"OK" completionHandler:^(NSInteger buttonIndex) {
		[self dismissViewControllerAnimated:YES completion:NULL];
	}];
}

- (void) checkProductionFromTimer:(NSTimer *)timer
{
	if (!self.isCancelled) {
		NSString* production_uuid = [timer.userInfo objectForKey:kAuphonicProductionTimerKey];
		[self checkProduction:production_uuid];
	}
}

- (void) checkProduction:(NSString *)productionUUID
{
	LUAuphonic* client = [[LUAuphonic alloc] init];
	[client getDetailsForProduction:productionUUID withCompletion:^(NSString* outputURL, NSError* error) {
		if (error) {
			[self showError:error];
		}
		else if (outputURL.length > 0) {
			NSString* mp3_path = [self.episode.exportedPath stringByDeletingLastPathComponent];
			mp3_path = [mp3_path stringByAppendingPathComponent:@"exported.mp3"];
			[[NSFileManager defaultManager] removeItemAtPath:mp3_path error:NULL];

			[client downloadURL:outputURL toFile:mp3_path withCompletion:^(NSError *error) {
				if (error) {
					[self showError:error];
				}
				else {
					[[NSNotificationCenter defaultCenter] postNotificationName:kFinishedExportNotification object:self userInfo:@{ kFinishedExportFileKey: mp3_path }];
				}
			}];
		}
		else {
			self.checkProductionTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkProductionFromTimer:) userInfo:@{ kAuphonicProductionTimerKey: productionUUID } repeats:NO];
		}
	}];
}

- (void) convertToMP3
{
	[self.episode convertToMP3WithCompletion:^(NSString *pathToFile) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kFinishedExportNotification object:self userInfo:@{ kFinishedExportFileKey: pathToFile }];
		});
	}];
}

@end
