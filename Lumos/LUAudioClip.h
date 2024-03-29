//
//  LUAudioRecorder.h
//  Lumos
//
//  Created by Jonathan Hays on 3/13/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EZAudioPlot;

@interface LUAudioClip : NSObject

	- (instancetype) initWithDestination:(NSURL*)destinationUrl;
	- (void) play;
	- (void) stop;

	- (UIImage*) waveFormImage;
	- (UIView*) requestAudioInputView;
	- (UIImage*) renderWaveImage:(CGSize)size;
	- (EZAudioPlot *) getPlot;

	// Set the callback if you want to be notified when the playback of the audio completes. Optional.
	@property (nonatomic, copy) void (^playbackCompleteCallback)(LUAudioClip* recorder);

	// Where did this file get written
	@property (nonatomic, strong) NSURL* destination;
	@property (nonatomic, readonly) NSTimeInterval duration;
	@property (nonatomic, readonly) NSString* durationString;

@end
