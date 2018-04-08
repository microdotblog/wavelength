//
//  LUNewBlogController.h
//  Wavelength
//
//  Created by Manton Reece on 4/5/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUNewBlogController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField* sitenameField;
@property (strong, nonatomic) IBOutlet UILabel* summaryField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@end
