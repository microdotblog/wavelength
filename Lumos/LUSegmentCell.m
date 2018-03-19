//
//  LUSegmentCell.m
//  Lumos
//
//  Created by Manton Reece on 3/15/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSegmentCell.h"

@implementation LUSegmentCell

- (void) setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	if (selected) {
		self.previewImageView.layer.borderColor = [UIColor blackColor].CGColor;
	}
	else {
		self.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	}
}

- (void) updatePercentComplete:(CGFloat)value
{
	if (value == 0.0) {
		self.positionLine.hidden = YES;
	}
	else {
		CGFloat x = self.bounds.size.width * value;
		CGRect r = self.positionLine.frame;
		r.origin.x = x;
		self.positionLine.frame = r;
		self.positionLine.hidden = NO;
	}
}

@end
