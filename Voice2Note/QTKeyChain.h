//
//  QTKeyChain.h
//  Voice2Note
//
//  Created by Tang Qi on 3/25/16.
//  Copyright © 2016 jinxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface QTKeyChain : NSObject

+ (void)save:(NSString *)service data:(id)data;

+ (id)load:(NSString *)service;

+ (void)delete:(NSString *)service;

@end
