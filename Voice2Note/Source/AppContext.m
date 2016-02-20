//
//  AppContext.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-30.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "AppContext.h"

static NSString *kHasUploadAddressBookKey = @"kHasUploadAddressBookKey";

@implementation AppContext

+ (instancetype)appContext {
    static id instance = nil;
    static dispatch_once_t onceToken = 0L;
    dispatch_once(&onceToken, ^{
        instance = [[AppContext alloc] init];
    });
    return instance;
}

/**
 *  没实际作用(>_<)
 */
- (BOOL)hasUploadAddressBook {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kHasUploadAddressBookKey] boolValue];
}

- (void)setHasUploadAddressBook:(BOOL)hasUploadAddressBook {
    [[NSUserDefaults standardUserDefaults] setBool:hasUploadAddressBook forKey:kHasUploadAddressBookKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
