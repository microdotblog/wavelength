//
//  LUSelectBlogController.h
//  Wavelength
//
//  Created by Manton Reece on 4/4/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUSelectBlogController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@property (strong, nonatomic) NSArray* blogs; // NSDictionary (uid, name)

@end
