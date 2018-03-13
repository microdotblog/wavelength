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
@end

@implementation LUMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL* path = [self generateTimeStampedFilePath];
    self.audioRecorder = [[LUAudioRecorder alloc] initWithDestination:path];
}

- (NSURL*) generateTimeStampedFilePath
{
	NSURL* documentsDirectory = [self applicationDocumentsDirectory];
	
	NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSString* dateString = [now description];
	NSString* fileName = [NSString stringWithFormat:@"%@.caf", dateString];
	
	NSURL* recorderFilePath = [documentsDirectory URLByAppendingPathComponent:fileName];
	return recorderFilePath;
}

- (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (IBAction) onRecord:(id)sender
{
	[self.audioRecorder record];
}


@end
