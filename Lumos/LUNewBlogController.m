//
//  LUNewBlogController.m
//  Wavelength
//
//  Created by Manton Reece on 4/5/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUNewBlogController.h"

#import "RFClient.h"
#import "UUAlert.h"

@interface LUNewBlogController ()

@end

@implementation LUNewBlogController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupPricingSummary];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.sitenameField becomeFirstResponder];
}

- (void) setupPricingSummary
{
	self.summaryField.text = @"";
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/info"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		dispatch_async (dispatch_get_main_queue(), ^{
			if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
				BOOL has_subscription = [[response.parsedResponse objectForKey:@"has_subscription"] boolValue];
				if (has_subscription) {
					self.summaryField.text = @"$10/month will be added to your subscriptions. You can cancel any time.";
				}
				else {
					self.summaryField.text = @"Free 10-day trial. You can upgrade for $10/month at Micro.blog on the web.";
				}
			}
		});
	}];
}

- (void) showError:(NSString *)error
{
	[self.progressSpinner stopAnimating];
	[UUAlertViewController uuShowOneButtonAlert:@"Error Creating Microblog" message:error button:@"OK" completionHandler:NULL];
}

- (IBAction) finish:(id)sender
{
	NSString* sitename = self.sitenameField.text;
	if (sitename.length > 0) {
		[self.progressSpinner startAnimating];
	
		NSDictionary* info = @{
			@"sitename": sitename,
			@"theme": @"default",
			@"plan": @"site10"
		};
		
		RFClient* client = [[RFClient alloc] initWithPath:@"/account/charge/site"];
		[client postWithObject:info queryArguments:nil completion:^(UUHttpResponse *response) {
			dispatch_async (dispatch_get_main_queue(), ^{
				if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
					NSString* error = [response.parsedResponse objectForKey:@"error"];
					if (error) {
						[self showError:error];
					}
					else {
						NSString* uid = [NSString stringWithFormat:@"https://%@.micro.blog/", sitename];
						NSString* name = [NSString stringWithFormat:@"%@.micro.blog", sitename];
						
						[[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"Wavelength:blog:uid"];
						[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Wavelength:blog:name"];
						[[NSUserDefaults standardUserDefaults] synchronize];

						[self dismissViewControllerAnimated:YES completion:NULL];
					}
				}
				else if (response.httpError) {
					[self showError:[response.httpError localizedDescription]];
				}
			});
		}];
	}
}

@end
