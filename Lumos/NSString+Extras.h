//
//  NSString+Extras.h
//  Wavelength
//
//  Created by Manton Reece on 3/8/24.
//  Copyright © 2024 Micro.blog. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extras)

- (NSString *) mb_filenameWithAppearance;
- (NSString *) mb_filenameWithAppearance:(NSString *)mode;

@end

NS_ASSUME_NONNULL_END
