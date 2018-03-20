//
//  LUEditController.h
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "PopoverView.h"

@class LUEpisode;

@interface LUEditController : UIViewController <PopoverViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView* _Nonnull collectionView;
@property (strong, nonatomic) IBOutlet UIView* _Nonnull addPopoverView;
@property (strong, nonatomic) IBOutlet UIButton* _Nonnull playPauseButton;
@property (strong, nonatomic) IBOutlet UIView* _Nonnull recordingDimView;
@property (strong, nonatomic) IBOutlet UILabel* _Nonnull timerLabel;

@property (strong, nonatomic) LUEpisode* _Nullable episode;
@property (weak, nonatomic) PopoverView* _Nullable addPopover;
@property (strong, nonatomic) AVPlayer* _Nullable player;

@end
