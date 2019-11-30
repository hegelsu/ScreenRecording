//
//  KWScreenCapture.h
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//
//屏幕捕捉
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN
@protocol KWScreenCaptureDelegate;
@interface KWScreenCapture : NSObject

@property (nonatomic,weak)id<KWScreenCaptureDelegate> delegate;

@property (nonatomic,strong)CALayer *captureLayer;//屏幕捕捉层
@property (nonatomic,assign)NSUInteger frameRate;//帧率
@property (nonatomic,assign)CGFloat spaceTime;//间隔（秒）

@property (nonatomic,copy)NSString *capturePath;//存放路径

- (void)startCapture;//开始捕捉
- (void)stopCapture;//停止捕捉
- (void)clean;//清除缓存

@end

@protocol KWScreenCaptureDelegate <NSObject>

//捕捉结束
- (void)captureCompletedWithScreenCaptureFilePath:(NSString *)screenCaptureFilePath;
//失败
- (void)captureFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
