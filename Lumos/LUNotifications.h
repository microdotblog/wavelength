//
//  LUNotifications.h
//  Lumos
//
//  Created by Jonathan Hays on 3/23/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#ifndef LUNotifications_h
#define LUNotifications_h

static NSString* const kMicroblogConfiguredNotification = @"MicroblogConfiguredNotification";
static NSString* const kDefaultBlogsUpdatedNotification = @"DefaultBlogsUpdatedNotification";

static NSString* const kReplaceSegmentNotification = @"ReplaceSegmentNotification";
static NSString* const kReplaceSegmentOriginalKey = @"original"; // LUSegment
static NSString* const kReplaceSegmentNewArrayKey = @"new"; // NSArray of m4a paths

static NSString* const kFinishedExportNotification = @"FinishedExportNotification";
static NSString* const kFinishedExportFileKey = @"mp3_path";

static NSString* const kSeekAudioSegmentNotification = @"SeekAudioSegmentNotification";
static NSString* const kSeekAudioSegmentFileKey = @"path";
static NSString* const kSeekAudioSegmentPercent = @"fraction";

static NSString* const kRecordingDeviceChangedNotification = @"kRecordingDeviceChangedNotification";

#endif /* LUNotifications_h */
