//
//  LUAudioCache.h
//  Wavelength
//
//  Created by Manton Reece on 3/13/24.
//  Copyright © 2024 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LUAudioClip;
@class LUAudioRecorder;

NS_ASSUME_NONNULL_BEGIN

@interface LUAudioCache : NSObject

+ (UIImage *) thumbnailForClip:(LUAudioClip *)clip;
+ (UIImage *) thumbnailForRecorder:(LUAudioRecorder *)recorder;

@end

NS_ASSUME_NONNULL_END
