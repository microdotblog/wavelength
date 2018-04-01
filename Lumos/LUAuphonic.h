//
//  LUAuphonic.h
//  Wavelength
//
//  Created by Manton Reece on 3/30/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFClient.h"

@interface LUAuphonic : RFClient

+ (NSString *) savedUsername;
+ (void) clearSignin;

- (void) signInWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(NSError* error))handler;
- (void) createProductionWithCompletion:(void (^)(NSString* productionUUID, NSError* error))handler;
- (void) sendAudio:(NSData *)data toProduction:(NSString *)productionUUID withCompletion:(void (^)(NSError* error))handler;
- (void) startProduction:(NSString *)productionUUID withCompletion:(void (^)(NSError* error))handler;
- (void) getDetailsForProduction:(NSString *)productionUUID withCompletion:(void (^)(NSString* outputURL, NSError* error))handler;
- (void) downloadURL:(NSString *)audioURL toFile:(NSString *)path withCompletion:(void (^)(NSError* error))handler;

@end
