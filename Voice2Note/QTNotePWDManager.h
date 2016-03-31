//
//  QTNotePWDManager.h
//  Voice2Note
//
//  Created by Tang Qi on 3/25/16.
//  Copyright © 2016 jinxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QTNotePWDManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *notePWD;

/**
 *  存储密码
 *
 *  @param password    密码
 *  @param indexOfNote 笔记的 index
 */
- (void)savePassWord:(NSString *)password index:(NSString *)indexOfNote;

/**
 *  读取指定密码
 *
 *  @param indexOfNote 笔记的 index
 *
 *  @return 指定的密码
 */
- (id)readPassWord:(NSString *)indexOfNote;

/**
 *  删除密码
 */
+ (void)deletePassWord;

@end
