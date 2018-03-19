//
//  LUSegmentCell.h
//  Lumos
//
//  Created by Manton Reece on 3/15/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LUSegmentCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;
@property (strong, nonatomic) IBOutlet UIView* positionLine;

- (void) updatePercentComplete:(CGFloat)value;

@end
