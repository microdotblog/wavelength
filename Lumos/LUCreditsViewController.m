//
//  LUCreditsViewController.m
//  Wavelength
//
//  Created by Jonathan Hays on 4/4/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUCreditsViewController.h"

@import WebKit;

@implementation LUCreditsViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

	[self setupNavigation];
	[self setupWebView];
	
	[self performSelector:@selector(showWebView) withObject:nil afterDelay:0.5];
}

- (void) setupNavigation
{
	self.navigationItem.title = @"Credits";
	self.navigationController.navigationBarHidden = NO;
}

- (void) setupWebView
{
	self.webView.alpha = 0.0;
	
	NSString* path = [[NSBundle mainBundle] bundlePath];
	NSString* creditsPath = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
	NSString* html = [NSString stringWithContentsOfFile:creditsPath encoding:NSUTF8StringEncoding error:nil];
	[self.webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:path]];
}

- (void) showWebView
{
	[UIView animateWithDuration:0.3 animations:^{
			self.webView.alpha = 1.0;
	}];
}

@end
