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

@interface LUEpisode()
	@property (strong, nonatomic) NSMutableArray* audioSegmentPaths;
@end

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

- (id) init
{
	self = [super init];
	if (self)
	{
		self.audioSegmentPaths = [NSMutableArray array];
	}
	
	return self;
}

- (id) initWithFolder:(NSString *)path
{
	self = [super init];
	if (self) {
		self.path = path;
		
		self.title = [path lastPathComponent];

		self.audioSegmentPaths = [NSMutableArray array];
		
		NSString* preview_path = [path stringByAppendingPathComponent:@"preview.png"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:preview_path])
		{
			self.previewImage = [[UIImage alloc] initWithContentsOfFile:preview_path];
		}
		else
		{
			return nil;
		}
		
		[self loadFileInfo];
	}
	
	return self;
}


- (void) loadFileInfo
{
	NSString* clips_info_path = [self.path stringByAppendingPathComponent:@"clips.plist"];
	NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:clips_info_path];
	NSArray* foundArray = [dictionary objectForKey:@"clips"];
	
	if (foundArray)
	{
		self.audioSegmentPaths = [NSMutableArray array];
		for (NSString* relativePath in foundArray)
		{
			NSString* fullPath = [self.path stringByAppendingPathComponent:relativePath];
			[self.audioSegmentPaths addObject:fullPath];
		}
	}
	
	if (!self.audioSegmentPaths.count)
	{
		NSMutableArray* foundClips = [NSMutableArray array];

		NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
		for (NSString* filename in contents) {
			NSString* e = [filename pathExtension];
			if ([e isEqualToString:@"caf"] || [e isEqualToString:@"m4a"]) {
				NSString* s = [self.path stringByAppendingPathComponent:filename];
				[foundClips addObject:s];
			}
		}
		
		self.audioSegmentPaths = foundClips;
		[self saveFileInfo];
	}
}

- (void) saveFileInfo
{
	NSString* clips_info_path = [self.path stringByAppendingPathComponent:@"clips.plist"];
	
	NSMutableArray* relativePaths = [NSMutableArray array];
	for (NSString* absolutePath in self.audioSegmentPaths)
	{
		NSString* fileName = absolutePath.lastPathComponent;
		[relativePaths addObject:fileName];
	}
	
	NSDictionary* clipDictionary = @{ @"clips" : relativePaths };
	[clipDictionary writeToFile:clips_info_path atomically:YES];
}

- (void) addRecording:(NSString *)path
{
	[self.audioSegmentPaths addObject:path];	
	[self saveFileInfo];
}

- (void) addFile:(NSString *)path
{
	NSString* e = [path pathExtension];
	NSString* filename = [[NSString uuGenerateUUIDString] stringByAppendingPathExtension:e];
	NSString* dest_path = [self.path stringByAppendingPathComponent:filename];
	[[NSFileManager defaultManager] copyItemAtPath:path toPath:dest_path error:NULL];
	
	[self.audioSegmentPaths addObject:dest_path];
	
	[self saveFileInfo];
}

- (void) updateAudioSegmentOrder:(NSArray*)updatedSegmentPaths
{
	self.audioSegmentPaths = [NSMutableArray arrayWithArray:updatedSegmentPaths];
	[self saveFileInfo];
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
