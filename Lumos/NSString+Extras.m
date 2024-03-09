//
//  NSString+Extras.m
//  Wavelength
//
//  Created by Manton Reece on 3/8/24.
//  Copyright © 2024 Micro.blog. All rights reserved.
//

#import "NSString+Extras.h"

#import <UIKit/UIKit.h>

@implementation NSString (Extras)

- (NSString *) mb_filenameWithAppearance
{
	NSString* e = [self pathExtension];
	NSString* without_extension = [self stringByReplacingOccurrencesOfString:e withString:@""];

	NSString* mode = @"light";
	UITraitCollection* trait_collection = [UIScreen mainScreen].traitCollection;
	if ([trait_collection userInterfaceStyle] == UIUserInterfaceStyleDark) {
		mode = @"dark";
	}

	NSString* new_filename = [without_extension stringByAppendingFormat:@"%@.%@", mode, e];
	NSLog(@"new filename %@", new_filename);
	return new_filename;
}

@end
