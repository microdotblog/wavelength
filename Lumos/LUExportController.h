//
//  LUExportController.h
//  Wavelength
//
//  Created by Manton Reece on 3/31/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LUEpisode;

@interface LUExportController : UIViewController

@property (strong, nonatomic) IBOutlet UIView* containerView;

@property (strong, nonatomic) LUEpisode* episode;

@end
