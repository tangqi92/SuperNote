//
//  QTNotePWDManager.m
//  Voice2Note
//
//  Created by Tang Qi on 3/25/16.
//  Copyright © 2016 jinxing. All rights reserved.
//

#import "QTKeyChain.h"
#import "QTNotePWDManager.h"


@implementation QTNotePWDManager

static NSString *const kRHKeyChainKey = @"me.itangqi.supernote.keychainKey";

- (void)savePassWord:(NSString *)password index:(NSString *)indexOfNote {
   
    if (!_notePWD) {
            _notePWD = [NSMutableDictionary dictionary];
    }
    [_notePWD setObject:password forKey:indexOfNote];
    [QTKeyChain save:kRHKeyChainKey data:_notePWD];
}

- (id)readPassWord:(NSString *)indexOfNote {
    _notePWD = (NSMutableDictionary *) [QTKeyChain load:kRHKeyChainKey];
    return [_notePWD objectForKey:indexOfNote];
}

+ (void)deletePassWord{
    [QTKeyChain delete:kRHKeyChainKey];
}
@end
