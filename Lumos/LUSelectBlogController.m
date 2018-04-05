//
//  LUSelectBlogController.m
//  Wavelength
//
//  Created by Manton Reece on 4/4/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSelectBlogController.h"

#import "LUBlogCell.h"

@interface LUSelectBlogController ()

@end

@implementation LUSelectBlogController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.blogs = @[ @{ @"name": @"testing" } ];
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.blogs.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LUBlogCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"BlogCell"];
	
	NSDictionary* info = [self.blogs objectAtIndex:indexPath.row];
	cell.nameField.text = [info objectForKey:@"name"];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//	NSDictionary* info = [self.blogs objectAtIndex:indexPath.row];
}

@end
