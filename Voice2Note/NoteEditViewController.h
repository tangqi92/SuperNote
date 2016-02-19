//
//  YYTextEditExample.h
//  YYKitExample
//
//  Created by ibireme on 15/9/3.
//  Copyright (c) 2015 ibireme. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>
@class VNNote;

@interface NoteEditViewController : UIViewController

// 返回类型和调用方法的对象类型相同
- (instancetype)initWithNote:(VNNote *)note;

@end
