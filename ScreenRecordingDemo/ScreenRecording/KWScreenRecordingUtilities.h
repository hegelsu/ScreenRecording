//
//  KWScreenRecordingUtilities.h
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KWScreenRecordingUtilities : NSObject

/// 合并视频
/// @param screenCaptureFilePath 屏幕捕捉文件地址
/// @param audioPath 录音文件地址
/// @param target <#target description#>
/// @param action <#action description#>
+ (void)mergeVideoWithScreenCaptureFilePath:(NSString *)screenCaptureFilePath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action;

+ (void)clean;

@end

NS_ASSUME_NONNULL_END
