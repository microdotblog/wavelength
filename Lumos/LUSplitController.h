//
//  LUSplitController.h
//  Lumos
//
//  Created by Manton Reece on 3/20/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class LUSegment;
@class LUAudioClip;

@interface LUSplitController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView* _Nonnull scrollView;
@property (strong, nonatomic) IBOutlet UIButton* _Nonnull playPauseButton;
@property (strong, nonatomic) IBOutlet UIButton* _Nonnull splitButton;

@property (strong, nonatomic) LUSegment* _Nullable segment;
@property (strong, nonatomic) LUAudioClip* _Nullable clip;
@property (strong, nonatomic) AVPlayer* _Nullable player;
@property (assign, nonatomic) NSTimeInterval splitSeconds;
@property (strong, nonatomic) NSString* _Nullable part1File;
@property (strong, nonatomic) NSString* _Nullable part2File;

@end
