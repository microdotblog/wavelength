//
//  LUSegmentCell.h
//  Lumos
//
//  Created by Manton Reece on 3/15/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LUAudioClip;

@interface LUSegmentCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;
@property (strong, nonatomic) IBOutlet UIView* positionLine;
@property (strong, nonatomic) IBOutlet UILabel* durationField;

@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;
@property (strong, nonatomic) NSString* path;
@property (assign, nonatomic) BOOL isEpisodePlaying;

- (void) setupWithFile:(NSString *)path;
- (void) updatePercentComplete:(CGFloat)value;
- (void) setPlaying:(BOOL)isPlaying;

@end
