//
//  QTClickImageView.h
//  Voice2Note
//
//  Created by Tang Qi on 3/16/16.
//  Copyright © 2016 jinxing. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QTClickImageViewDelegate <NSObject>

// 代理方法
- (void)didSelectItemWith;

@end

@interface QTClickImageView : UIImageView

// 声明了一个代理的属性
@property (nonatomic, weak) id<QTClickImageViewDelegate> delegate;

@end
