//
//  AppDelegate.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "AppDelegate.h"
#import "NoteListViewController.h"
#import "NoteManager.h"
#import "UIColor+VNHex.h"
#import "VNConstants.h"
#import "VNNote.h"
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // 注册本地通知
    // 判断当前设备的系统版本是否大于8.0 若是则需注册
    // Since iOS 8 you need to ask user's permission to show notifications from your app, this applies for both remote/push and local notifications.
    if ([UIDevice currentDevice].systemVersion.floatValue > 8.0) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];

        [application registerUserNotificationSettings:settings];
    }

    // 初始化笔记
    [self addInitFileIfNeeded];

    /* customize navigation style */
    [[UINavigationBar appearance] setBarTintColor:[UIColor systemColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    NSDictionary *navbarTitleTextAttributes = [NSDictionary
        dictionaryWithObjectsAndKeys:[UIColor whiteColor],
                                     NSForegroundColorAttributeName, nil];
    [[UINavigationBar appearance]
        setTitleTextAttributes:navbarTitleTextAttributes];

    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleLightContent];

    NoteListViewController *noteListViewController = [[NoteListViewController alloc] init];
    UINavigationController *rootViewController = [[UINavigationController alloc] initWithRootViewController:noteListViewController];

    self.window.rootViewController = rootViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an
    // incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down
    // OpenGL ES frame rates. Games should use this method to pause the game.
    // 图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate
    // timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called
    // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the
    // application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if
    // appropriate. See also applicationDidEnterBackground:.
}

- (void)addInitFileIfNeeded {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:@"hasInitFile"]) {
        VNNote *note =
            [[VNNote alloc] initWithTitle:nil
                                  content:NSLocalizedString(@"AboutText", @"")
                              createdDate:[NSDate date]
                               updateDate:[NSDate date]];
        [[NoteManager sharedManager] storeNote:note];
        [userDefaults setBool:YES forKey:@"hasInitFile"];
        // 立即同步
        [userDefaults synchronize];
    }
}

/**
 *  本地通知注册成功后调用的方法
 */
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSLog(@"本地通知注册成功");
}

/**
 *  本地通知注册失败调用的方法
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"error is:%@", error);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kAppName message:notification.alertBody delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];

    NSDictionary *dic = [[NSDictionary alloc] init];
    // 这里可以接受到本地通知中心发送的消息
    dic = notification.userInfo;
    NSLog(@"user info = %@", [dic objectForKey:@"key"]);

    // 图标上的数字减 1
    application.applicationIconBadgeNumber -= 1;

    // 移除当前所有的本地通知
    [application cancelAllLocalNotifications];

    // 移除指定的通知
    [application cancelLocalNotification:notification];
}

@end
