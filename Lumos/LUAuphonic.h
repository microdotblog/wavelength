//
//  LUAuphonic.h
//  Wavelength
//
//  Created by Manton Reece on 3/30/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LUAuphonic : NSObject

+ (NSString *) savedUsername;

- (void) signInWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(NSError* error))handler;

@end
