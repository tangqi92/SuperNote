//
//  VNNote.h
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define VNNOTE_DEFAULT_TITLE @"无标题笔记"

// 遵循 NSCoding 协议
@interface VNNote : NSObject <NSCoding>

// NSString 如果使用 strong, 那么这个属性就有可能指向一个可变对象，如果这个可变对象在外部被修改了，那么会影响该属性
@property (nonatomic, copy) NSString *noteID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, strong) NSDate *updatedDate;
@property (nonatomic, assign) NSInteger index;
// 行高缓存
@property (nonatomic, assign) CGFloat cellHeight;

- (id)initWithTitle:(NSString *)title
            content:(NSString *)content
        createdDate:(NSDate *)createdDate
         updateDate:(NSDate *)updatedDate;

- (BOOL)Persistence;

@end
