//
//  LUEpisodeCell.h
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUEpisodeCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* titleField;
@property (strong, nonatomic) IBOutlet UILabel* durationField;
@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;

@end
