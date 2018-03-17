//
//  LUEpisode.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUEpisode.h"

#import "UUString.h"

@implementation LUEpisode

- (id) initWithFolder:(NSString *)path
{
	self = [super init];
	if (self) {
		self.path = path;
		
		self.title = [path lastPathComponent];
		self.duration = @"30s"; // FIXME

		NSString* preview_path = [path stringByAppendingPathComponent:@"preview.png"];
		self.previewImage = [[UIImage alloc] initWithContentsOfFile:preview_path];
	}
	
	return self;
}

- (NSArray *) audioSegmentPaths
{
	NSMutableArray* paths = [NSMutableArray array];
	NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
	for (NSString* filename in contents) {
		NSString* e = [filename pathExtension];
		if ([e isEqualToString:@"caf"] || [e isEqualToString:@"m4a"]) {
			NSString* s = [self.path stringByAppendingPathComponent:filename];
			[paths addObject:s];
		}
	}
	
	return paths;
}

- (void) addFile:(NSString *)path
{
	NSString* e = [path pathExtension];
	NSString* filename = [[NSString uuGenerateUUIDString] stringByAppendingPathExtension:e];
	NSString* dest_path = [self.path stringByAppendingPathComponent:filename];
	[[NSFileManager defaultManager] copyItemAtPath:path toPath:dest_path error:NULL];
}

@end
