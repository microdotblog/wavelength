//
//  LUEpisodeCell.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUEpisodeCell.h"

#import "LUEpisode.h"

@implementation LUEpisodeCell

- (void) setupWithEpisode:(LUEpisode *)episode
{
	self.titleField.text = episode.title;
	self.previewImageView.image = episode.previewImage;

	self.previewImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	self.previewImageView.layer.borderWidth = 0.5;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

@end