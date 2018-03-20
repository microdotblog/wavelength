//
//  LUSegment.h
//  Lumos
//
//  Created by Manton Reece on 3/20/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LUEpisode;

@interface LUSegment : NSObject

@property (strong) NSString* path;
@property (strong) LUEpisode* episode;

@end
