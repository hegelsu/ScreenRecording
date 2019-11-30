//
//  KWAudioRecord.h
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//
//录音
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol KWAudioRecordDelegate;
@interface KWAudioRecord : NSObject

@property (nonatomic,weak)id<KWAudioRecordDelegate> delegate;

@property (nonatomic,copy)NSString *audioPath;//存放路径

- (void)startRecord;//开始录制
- (void)stopRecord;//结束录制
- (void)clean;//清除缓存

@end

@protocol KWAudioRecordDelegate <NSObject>

- (void)audioRecordCompletedWithAudioRecordFilePath:(NSString *)audioRecordFilePath;

@end

NS_ASSUME_NONNULL_END
