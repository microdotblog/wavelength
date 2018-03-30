//
//  LUSettingsViewController.h
//  Lumos
//
//  Created by Jonathan Hays on 3/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUSettingsViewController : UIViewController
	@property (nonatomic, strong) IBOutlet UILabel* versionNumber;
	@property (nonatomic, strong) IBOutlet UILabel* userName;
	@property (nonatomic, strong) IBOutlet UILabel* blogName;
	@property (nonatomic, strong) IBOutlet UIButton* loginButton;
@end
