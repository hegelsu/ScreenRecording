//
//  KWSc reenRecordingManager.h
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//
//录屏管理器
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN
@protocol KWScreenRecordingManagerDelegate;
@interface KWScreenRecordingManager : NSObject

@property (nonatomic,weak)id<KWScreenRecordingManagerDelegate> delegate;

@property (nonatomic,strong)CALayer *captureLayer;//屏幕捕捉层
@property (nonatomic,assign)NSUInteger frameRate;//帧率
@property (nonatomic,assign)CGFloat spaceTime;//间隔（秒）

+ (instancetype)shareManager;

- (void)screenRecordStart;//开始
- (void)screenRecordPause;//暂停
- (void)screenRecordResume;//继续
- (void)screenRecordStop;//结束
- (void)screenRecordClean;//清除

@end

@protocol KWScreenRecordingManagerDelegate <NSObject>
//完成录制
- (void)screenRecordingCompleteWithScreenRecordingFilePath:(NSString *)screenRecordingFilePath;
//录制失败
- (void)screenRecordingFailedWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
