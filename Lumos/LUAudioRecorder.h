//
//  LUAudioRecorder.h
//  Lumos
//
//  Created by Jonathan Hays on 3/19/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LUAudioClip.h"

@interface LUAudioRecorder : LUAudioClip
	// Safety check on global settings to see if the device can record
	+ (BOOL) canRecord;

	// Create a unique, time stamped file URL in the Documents directory
	+ (NSURL*) generateTimeStampedFileURL;

	- (instancetype) initWithDestination:(NSURL*)destinationUrl;

	- (void) record;
	- (void) stop;

	@property (nonatomic, copy) void (^recordProgressCallback)(NSString* timeString);
	@property (nonatomic, strong) NSString* customDeviceName;

@end
