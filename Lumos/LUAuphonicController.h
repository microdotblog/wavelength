//
//  LUAuphonicController.h
//  Wavelength
//
//  Created by Manton Reece on 3/30/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUAuphonicController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField* usernameField;
@property (strong, nonatomic) IBOutlet UITextField* passwordField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@end
