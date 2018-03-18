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
@property (strong, readonly) NSString* duration;

- (id) initWithFolder:(NSString *)path;
- (NSArray *) audioSegmentPaths;
- (void) addFile:(NSString *)path;

@end
