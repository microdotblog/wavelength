//
//  LUEditController.h
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopoverView.h"

@class LUEpisode;

@interface LUEditController : UIViewController <PopoverViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;
@property (strong, nonatomic) IBOutlet UIView* addPopoverView;

@property (strong, nonatomic) LUEpisode* episode;
@property (weak, nonatomic) PopoverView* addPopover;

@end
