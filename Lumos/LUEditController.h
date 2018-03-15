//
//  LUEditController.h
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LUEpisode;

@interface LUEditController : UIViewController

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) LUEpisode* episode;

@end
