//
//  LUAudioCache.m
//  Wavelength
//
//  Created by Manton Reece on 3/13/24.
//  Copyright © 2024 Jonathan Hays. All rights reserved.
//

#import "LUAudioCache.h"

#import "LUAudioClip.h"
#import "LUAudioRecorder.h"
#import "NSString+Extras.h"
#import "EZAudioPlot.h"

@implementation LUAudioCache

+ (UIImage *) thumbnailForClip:(LUAudioClip *)clip
{
	UIImage* result = nil;
	
	NSString* thumbnail_filename = [clip.destination lastPathComponent];
	NSURL* thumbnail_base = [clip.destination URLByDeletingLastPathComponent];
	thumbnail_filename = [thumbnail_filename stringByAppendingString:[@"-thumbnail.png" mb_filenameWithAppearance]];
	NSURL* thumbnail_url = [thumbnail_base URLByAppendingPathComponent:thumbnail_filename];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnail_url.path]) {
		result = [UIImage imageWithContentsOfFile:thumbnail_url.path];
	}
	else {
		CGSize preview_size = CGSizeMake (150, 54);

		UIImage* image = [clip renderWaveImage:preview_size];
		if (image) {
			NSData* imageData = UIImagePNGRepresentation(image);
			if (imageData) {
				NSError* error = nil;
				[imageData writeToURL:thumbnail_url options:NSDataWritingFileProtectionNone error:&error];
				if (error) {
					NSLog(@"Error: %@", error);
				}
			}
			
			result = image;
		}
		else {
			NSLog(@"Error: Unable to load or render waveform.");
		}
	}
	
	return result;
}

+ (UIImage *) thumbnailForRecorder:(LUAudioRecorder *)recorder
{
	UIImage* img = nil;
	
	NSString* episode_path = [recorder.destination URLByDeletingLastPathComponent].path;
	NSString* preview_filepath = [episode_path stringByAppendingPathComponent:[@"preview.png" mb_filenameWithAppearance]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:preview_filepath]) {
		img = [UIImage imageWithContentsOfFile:preview_filepath];
	}
	else {
		CGSize preview_size = CGSizeMake (150, 54);
		NSData* d;
		
		// light mode
		[recorder getPlot].color = [UIColor colorNamed:@"color_waveform_plot_light"];
		NSString* light_path = [episode_path stringByAppendingPathComponent:[@"preview.png" mb_filenameWithAppearance:@"light"]];
		img = [recorder renderWaveImage:preview_size];
		d = UIImagePNGRepresentation(img);
		[d writeToFile:light_path atomically:YES];
		
		// dark mode
		[recorder getPlot].color = [UIColor colorNamed:@"color_waveform_plot_dark"];
		NSString* dark_path = [episode_path stringByAppendingPathComponent:[@"preview.png" mb_filenameWithAppearance:@"dark"]];
		img = [recorder renderWaveImage:preview_size];
		d = UIImagePNGRepresentation(img);
		[d writeToFile:dark_path atomically:YES];

		// reset back to current appearance
		[recorder getPlot].color = [UIColor colorNamed:@"color_waveform_plot"];
		[recorder getPlot].backgroundColor = [UIColor colorNamed:@"color_segment_background"];
	}
	
	return img;
}

@end
