
//
//  QTClickImageView.m
//  Voice2Note
//
//  Created by Tang Qi on 3/16/16.
//  Copyright © 2016 jinxing. All rights reserved.
//

#import "NoteEditViewController.h"
#import "QTClickImageView.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
static float kDuration = 0.3;

@interface QTClickImageView () <UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    // 用于按屏幕比例缩放图像
    UIView *containerView;
    // 用于保存缩放的图像
    UIView *snapShotView;
    // 利用 ScrollView 的缩放功能来缩放图像
    UIScrollView *containerScrollView;
    // 保存放大前原始图像在 Window 上的坐标
    CGRect originImageRect;
    // 设置动画时间
    CGFloat duration;
}

@end

@implementation QTClickImageView

/**
 *  StoryBoard 中初始化
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // 允许交互
        self.userInteractionEnabled = YES;
        // 为 UIImageView 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
        // 初始化时间
        duration = kDuration;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        // 为 UIImageView 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
        // 初始化时间
        duration = kDuration;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        self.userInteractionEnabled = YES;
        // 为 UIImageView 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
        // 初始化时间
        duration = kDuration;
    }
    return self;
}

- (void)tapImage:(UITapGestureRecognizer *)sender {

    [self showImage:(UIImageView *) sender.view];
}

- (void)showImage:(UIImageView *)originImageView {

    // 为获取应用程序的 window
    UIWindow *window = [UIApplication sharedApplication].windows[0];

    // 获取当前显示的 image
    UIImage *image = originImageView.image;
    // 将 imageview 的坐标转换到屏幕上的坐标位置
    originImageRect = [originImageView convertRect:originImageView.bounds toView:window];

    // 添加容器 containerScrollView
    containerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    containerScrollView.delegate = self;
    // 设置最大伸缩比例
    containerScrollView.maximumZoomScale = 3.0;
    // 添加容器 containerView, 用于缩放
    // 若图像的大小比例不是屏幕的大小，若直接缩放图像，缩放的时候会有位移偏差
    containerView = [UIView new];
    containerView.frame = containerScrollView.frame;
    containerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    // 用于缩放的方法
    snapShotView = [self snapshotViewAfterScreenUpdates:NO];
    snapShotView.frame = originImageRect;
    // 加载到屏幕上
    [containerView addSubview:snapShotView];
    [containerScrollView addSubview:containerView];
    [window addSubview:containerScrollView];
    // 添加全局手势，点击缩小回原位
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideImage:)];
    tap.numberOfTapsRequired = 1;
    tap.delegate = self;
    [containerScrollView addGestureRecognizer:tap];
    self.alpha = 0;

    // 移动到屏幕中央
    CGFloat rate = SCREEN_WIDTH / image.size.width;
    CGRect finalRect = CGRectMake(1, (SCREEN_HEIGHT - image.size.height * rate) / 2, SCREEN_WIDTH, image.size.height * rate);
    // 动画显示
    [UIWindow animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        snapShotView.frame = finalRect;
        containerScrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    }
        completion:^(BOOL finished) {
            // 隐藏状态栏
            [UIApplication.sharedApplication setStatusBarHidden:true withAnimation:UIStatusBarAnimationSlide];
        }];
}

- (void)hideImage:(UITapGestureRecognizer *)tap {
    [UIApplication.sharedApplication setStatusBarHidden:false withAnimation:UIStatusBarAnimationNone];
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        // 缩放到原始大小时，必须同时缩放到原始的倍率，否则放大的情况位置偏移
        containerScrollView.zoomScale = 1.0f;
        snapShotView.frame = originImageRect;
        containerScrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    }
        completion:^(BOOL finished) {
            self.alpha = 1;
            [containerScrollView removeFromSuperview];
        }];
}

#pragma mark - UIScrollView Delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // 缩放容器 containerView
    return containerView;
}

@end
