//
//  LUPostController.h
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LUEpisode;

@interface LUPostController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField* titleField;
@property (strong, nonatomic) IBOutlet UIView* titleContainer;
@property (strong, nonatomic) IBOutlet UITextView* textView;

@property (strong, nonatomic) LUEpisode* episode;

@end
