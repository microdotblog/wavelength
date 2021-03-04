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

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self clearSelection];
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

- (void) clearSelection
{
	NSIndexPath* index_path = self.tableView.indexPathForSelectedRow;
	if (index_path) {
		[self.tableView deselectRowAtIndexPath:index_path animated:NO];
	}
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
			NSString* msg = [NSString stringWithFormat:@"%@ can be upgraded to Micro.blog Premium ($10/month) to support both podcast and microblog hosting.", [info objectForKey:@"name"]];
			[UUAlertViewController uuShowTwoButtonAlert:@"Upgrade Subscription" message:msg buttonOne:@"Cancel" buttonTwo:@"Learn More" completionHandler:^(NSInteger buttonIndex) {
				if (buttonIndex == 0) {
					[self clearSelection];
				}
				else if (buttonIndex == 1) {
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://micro.blog/account/plans"] options:@{} completionHandler:NULL];
				}
			}];
		}
	}
	else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://micro.blog/new/premium"] options:@{} completionHandler:NULL];
	}
}

@end
