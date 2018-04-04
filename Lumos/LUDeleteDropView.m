//
//  LUDeleteDropView.m
//  Wavelength
//
//  Created by Manton Reece on 4/3/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUDeleteDropView.h"

#import "LUNotifications.h"
#import "LUSegment.h"

@implementation LUDeleteDropView

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	self.dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
	self.interactions = @[ self.dropInteraction ];

	self.layer.cornerRadius = 28.0;
	self.layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
	self.clipsToBounds = YES;
}

- (BOOL) dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session
{
	return YES;
}

- (void) dropInteraction:(UIDropInteraction *)interaction sessionDidEnter:(id<UIDropSession>)session
{
	self.layer.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
}

- (void) dropInteraction:(UIDropInteraction *)interaction sessionDidExit:(id<UIDropSession>)session
{
	self.layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
}

- (UIDropProposal *) dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session
{
	return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationMove];
}

- (void) dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session
{
	[session loadObjectsOfClass:[NSString class] completion:^(NSArray<__kindof id<NSItemProviderReading>> * _Nonnull objects) {
		NSString* dropped_path = [objects firstObject];

		LUSegment* segment = [[LUSegment alloc] init];
		segment.path = dropped_path;

		[[NSNotificationCenter defaultCenter] postNotificationName:kReplaceSegmentNotification object:self userInfo:@{
			kReplaceSegmentOriginalKey: segment,
			kReplaceSegmentNewArrayKey: @[]
		}];

	}];
}

@end
