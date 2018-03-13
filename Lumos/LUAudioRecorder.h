//
//  LUAudioRecorder.h
//  Lumos
//
//  Created by Jonathan Hays on 3/13/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LUAudioRecorder : NSObject

	// Safety check on global settings to see if the device can record
	+ (BOOL) canRecord;

	// Create a unique, time stamped file URL in the Documents directory
	+ (NSURL*) generateTimeStampedFileURL;


	- (instancetype) initWithDestination:(NSURL*)destinationUrl;
	- (void) record;
	- (void) play;
	- (void) stop;

	// Set the callback if you want to be notified when the playback of the audio completes. Optional.
	@property (nonatomic, copy) void (^playbackCompleteCallback)(LUAudioRecorder* recorder);
@end
