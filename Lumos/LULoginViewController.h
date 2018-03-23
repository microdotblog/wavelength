//
//  LULoginViewController.h
//  Lumos
//
//  Created by Jonathan Hays on 3/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LULoginViewController : UIViewController

	@property (nonatomic, strong) IBOutlet UITextField* loginField;
	@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* busyIndicator;

@end
