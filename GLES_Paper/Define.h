//
//  Define.h
//  Malena
//
//  Created by Dawn on 12-11-3.
//  Copyright (c) 2012年 Dawn. All rights reserved.
//

#import "AppDelegate.h"
#import "RootNavController.h"

#ifndef Artist_Define_h
#define Artist_Define_h

#define SCREEN_4_INCH           (SCREEN_HEIGHT == 568)                              // 4寸Retina
#define SCREEN_WIDTH			([[UIScreen mainScreen] bounds].size.width)         // Screen width
#define SCREEN_HEIGHT			([[UIScreen mainScreen] bounds].size.height)        // Screen height
#define NAV_HEIGHT              44                                                  // Nav height
#define STATUS_BAR_HEIGHT       0                                                  // Status bar height
#define MAINCONTENTHEIGHT       (SCREEN_HEIGHT - STATUS_BAR_HEIGHT - NAV_HEIGHT)    // Content height

// 判断系统版本是否大于x.x
#define IOSVersion_3_2			([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2)
#define IOSVersion_4			([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0)
#define IOSVersion_5			([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
#define IOSVersion_6			([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IOSVersion_7			([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)

// 判断当前ViewController的方向
#define INTERFACE_UNKNOWN               ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationUnknown)
#define INTERFACE_PORTRAIT              ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationPortrait)
#define INTERFACE_PORTRAITUPSIDEDOWN    ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationPortraitUpsideDown)
#define INTERFACE_LANDSCAPELEFT         ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationLandscapeLeft)
#define INTERFACE_LANDSCAPERIGHT        ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationLandscapeRight)
#define INTERFACE_FACEUP                ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationFaceUp)
#define INTERFACE_FACEDOWN              ([[UIApplication sharedApplication]statusBarOrientation] == UIDeviceOrientationFaceDown)


//常用函数
#define RESOURCEFILE(x,y)       [[NSBundle mainBundle] pathForResource:x ofType:y]
#define KEY_WINDOW  [[UIApplication sharedApplication]keyWindow]

// 程序版本号
#define APPVERSION              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define APP_ID                  @""
#define CHANNEL_ID              @""
#define APP_KEY                 @"1de32ab3d"
#define APP_SECRET                 @"a123456780"

// NSUserDefaults
#define USERDEFAULT_FEEDBACKNUM         @"FeedbackNum"

// UMeng
#define UMENG_KEY               @"523daa4056240b26a100bbaf"

// 网络请求
#define OPUS_SERVER_URL         @"http://115.28.43.148/artapi/opus/"
#define DOC_SERVER_URL          @"http://115.28.43.148/artapi/Doc/"
#define COMMENT_SERVER_URL      @"http://115.28.43.148/artapi/Comments/"
#define SNS_SERVER_URL          @"http://115.28.43.148/artapi/Socialmedia/"

// 颜色
#define RGBACOLOR(r,g,b,a)      [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define VIEWBGCOLOR             RGBACOLOR(39, 38, 39, 1)
#define TITLEBGCOLOR            RGBACOLOR(30, 30, 31, 1)
#define TEXTHCOLOR              RGBACOLOR(243, 152, 0, 1)

// 滑动框架
#define TRANS_SCALE 0.95
#define TRANS_ALPHA 0.4
#define TRANS_WIDTH 200
#define TRANS_WIDTH_RIGHT 320
#define ROOTNAV    ((RootNavController *)((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController)

#endif
