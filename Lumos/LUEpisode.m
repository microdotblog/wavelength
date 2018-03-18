//
//  LUEpisode.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUEpisode.h"
#import <EZAudio/EZAudio.h>
#import "UUString.h"

@implementation LUEpisode

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithFolder:(NSString *)path
{
	self = [super init];
	if (self) {
		self.path = path;
		
		self.title = [path lastPathComponent];

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

- (NSString*) duration
{
	NSArray* segments = [self audioSegmentPaths];
	
	NSTimeInterval duration = 0;
	for (NSString* path in segments)
	{
		NSURL* url = [NSURL fileURLWithPath:path];
		EZAudioFile* audioFile = [EZAudioFile audioFileWithURL:url];
		duration += audioFile.duration;
	}

	return [LUEpisode stringFromTimeInterval:duration];
}

@end
