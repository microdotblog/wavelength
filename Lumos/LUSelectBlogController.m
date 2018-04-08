//
//  LUSelectBlogController.m
//  Wavelength
//
//  Created by Manton Reece on 4/4/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSelectBlogController.h"

#import "LUBlogCell.h"
#import "RFClient.h"
#import "UUAlert.h"

@interface LUSelectBlogController ()

@end

@implementation LUSelectBlogController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupTable];
	[self fetchBlogs];
}

- (void) setupTable
{
	self.tableView.layer.cornerRadius = 8.0;
}

- (void) fetchBlogs
{
	[self.progressSpinner startAnimating];

	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (response.httpError) {
				[self showError:[response.httpError localizedDescription]];
			}
			else {
				self.blogs = [response.parsedResponse objectForKey:@"destination"];
				[self.tableView reloadData];
			}

			[self.progressSpinner stopAnimating];
		});
	}];
}

- (void) selectBlog:(NSDictionary*)blogInfo
{
	NSString* uid = [blogInfo objectForKey:@"uid"];
	NSString* name = [blogInfo objectForKey:@"name"];
	
	[[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"Wavelength:blog:uid"];
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Wavelength:blog:name"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) showError:(NSString *)error
{
	[self.progressSpinner stopAnimating];
	[UUAlertViewController uuShowOneButtonAlert:@"Error Creating Microblog" message:error button:@"OK" completionHandler:NULL];
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.blogs.count + 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LUBlogCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"BlogCell"];
	
	if (indexPath.row < self.blogs.count) {
		NSDictionary* info = [self.blogs objectAtIndex:indexPath.row];
		cell.nameField.text = [info objectForKey:@"name"];
		if ([[info objectForKey:@"microblog-audio"] boolValue]) {
			cell.subtitleField.text = @"This microblog is ready for podcasting.";
		}
		else {
			cell.subtitleField.text = @"Tap to upgrade this microblog for podcasting.";
		}
	}
	else {
		cell.nameField.text = @"New Blog + Microcast";
		cell.subtitleField.text = @"Create a new microblog for podcasting.";
	}
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < self.blogs.count) {
		NSDictionary* info = [self.blogs objectAtIndex:indexPath.row];
		if ([[info objectForKey:@"microblog-audio"] boolValue]) {
			[self selectBlog:info];
		}
		else {
			NSString* msg = [NSString stringWithFormat:@"%@ will be upgraded to the $10/month plan to support podcasting.", [info objectForKey:@"name"]];
			[UUAlertViewController uuShowTwoButtonAlert:@"Upgrade Subscription" message:msg buttonOne:@"Cancel" buttonTwo:@"Upgrade" completionHandler:^(NSInteger buttonIndex) {
				if (buttonIndex == 1) {
					NSString* uid = [info objectForKey:@"uid"];
					NSString* sitename = [uid stringByReplacingOccurrencesOfString:@".micro.blog" withString:@""];
					NSDictionary* params = @{
						@"sitename": sitename,
						@"theme": @"default",
						@"plan": @"site10"
					};
				
					RFClient* client = [[RFClient alloc] initWithPath:@"/account/charge/site"];
					[client postWithParams:params completion:^(UUHttpResponse* response) {
						dispatch_async (dispatch_get_main_queue(), ^{
							if (response.httpError) {
								[self showError:[response.httpError localizedDescription]];
							}
							else {
								[self selectBlog:info];
							}
						});
					}];
				}
			}];
		}
	}
	else {
		[self performSegueWithIdentifier:@"NewBlogSegue" sender:self];
	}
}

@end
