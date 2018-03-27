//
//  LUEpisode.h
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUEpisode : NSObject

@property (strong) NSString* path;
@property (strong) NSString* title;
@property (strong) UIImage* previewImage;
@property (strong) NSString* exportedPath;
@property (strong, readonly) NSString* duration;
@property (strong, readonly) NSMutableArray* audioSegmentPaths;

- (id) initWithFolder:(NSString *)path;
- (void) addFile:(NSString *)path;
- (void) addRecording:(NSString *)path;
- (void) updateAudioSegmentOrder:(NSArray*)updatedSegmentPaths;

@end
