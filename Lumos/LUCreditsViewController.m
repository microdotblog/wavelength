//
//  LUCreditsViewController.m
//  Wavelength
//
//  Created by Jonathan Hays on 4/4/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUCreditsViewController.h"
@import SafariServices;
@import WebKit;

@interface LUCreditsViewController ()

@end

@implementation LUCreditsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationItem.title = @"Credits";
	self.navigationController.navigationBarHidden = NO;

	NSString* path = [[NSBundle mainBundle] bundlePath];
	NSString* creditsPath = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
	NSString* html = [NSString stringWithContentsOfFile:creditsPath encoding:NSUTF8StringEncoding error:nil];
	[self.webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:path]];
}



@end
