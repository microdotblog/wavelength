//
//  LUSplitController.h
//  Lumos
//
//  Created by Manton Reece on 3/20/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LUSegment;

@interface LUSplitController : UIViewController

@property (strong, nonatomic) IBOutlet UIScrollView* _Nonnull scrollView;
@property (strong, nonatomic) IBOutlet UIButton* _Nonnull playPauseButton;
@property (strong, nonatomic) IBOutlet UIButton* _Nonnull splitButton;

@property (strong, nonatomic) LUSegment* _Nullable segment;

@end
