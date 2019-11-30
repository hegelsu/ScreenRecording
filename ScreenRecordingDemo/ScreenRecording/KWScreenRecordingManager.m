//
//  KWScreenRecordingManager.m
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//

#import "KWScreenRecordingManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "KWScreenCapture.h"
#import "KWAudioRecord.h"
#import "KWScreenRecordingUtilities.h"

typedef NS_ENUM(NSUInteger,KWScreenRecordingStatus) {
    KWScreenRecordingStatusNormal,//常态
    KWScreenRecordingStatusRecording,//录制
    KWScreenRecordingStatusPause,//暂停
};

@interface KWScreenRecordingManager ()<KWScreenCaptureDelegate,KWAudioRecordDelegate>{
    NSString *_screenCaptureFilePath;
    NSString *_audioRecordFilePath;
}

@property (nonatomic,strong)KWScreenCapture *screenCapture;
@property (nonatomic,strong)KWAudioRecord *audioRecord;

@property (nonatomic,assign)KWScreenRecordingStatus recordingStatus;

@end

@implementation KWScreenRecordingManager

static KWScreenRecordingManager *_instance = nil;

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [KWScreenRecordingManager new];
    });
    return _instance;
}

- (void)screenRecordStart{
    if (nil == self.captureLayer) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingFailedWithError:)]) {
            [self.delegate screenRecordingFailedWithError:[NSError errorWithDomain:@"no capture layer" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no capture layer"}]];
        }
        
        return ;
    }
    [self checkAuthorizationWithResultBlock:^(BOOL authorization) {
        if (authorization) {
            [self.screenCapture clean];
            [self.audioRecord clean];
            self.recordingStatus = KWScreenRecordingStatusRecording;
            [self.screenCapture startCapture];
            [self.audioRecord startRecord];
        }else{
            if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingFailedWithError:)]) {
                [self.delegate screenRecordingFailedWithError:[NSError errorWithDomain:@"no AVAuthorization" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no AVAuthorization"}]];
            }
        }
    }];
}
#pragma mark ---麦克风权限
- (void)checkAuthorizationWithResultBlock:(void(^)(BOOL authorization))resultBlock{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (AVAuthorizationStatusAuthorized == authStatus){//已授权
        if (resultBlock) {
            resultBlock(YES);
        }
        return;
    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        if (resultBlock) {
            resultBlock(granted);
        }
    }];
}
- (void)screenRecordPause{
    self.recordingStatus = KWScreenRecordingStatusPause;
    [self.audioRecord stopRecord];
    [self.screenCapture stopCapture];
}
- (void)screenRecordResume{
    self.recordingStatus = KWScreenRecordingStatusRecording;
    if (nil == self.captureLayer) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingFailedWithError:)]) {
            [self.delegate screenRecordingFailedWithError:[NSError errorWithDomain:@"no capture layer" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no capture layer"}]];
        }
        return;
    }
    [self.screenCapture startCapture];
    [self.audioRecord startRecord];
}
- (void)screenRecordStop{
    self.recordingStatus = KWScreenRecordingStatusNormal;
    [self.audioRecord stopRecord];
    [self.screenCapture stopCapture];
    
}
- (void)screenRecordClean{
    [self.screenCapture clean];
    [self.audioRecord clean];
    [KWScreenRecordingUtilities clean];
}
#pragma mark ---set方法
- (void)setFrameRate:(NSUInteger)frameRate{
    _frameRate = frameRate;
    self.screenCapture.frameRate = _frameRate;
}
- (void)setCaptureLayer:(CALayer *)captureLayer{
    _captureLayer = captureLayer;
    self.screenCapture.captureLayer = captureLayer;
}
#pragma mark ---KWScreenCaptureDelegate
- (void)captureCompletedWithScreenCaptureFilePath:(id)screenCaptureFilePath{
    _screenCaptureFilePath = screenCaptureFilePath;
    [KWScreenRecordingUtilities mergeVideoWithScreenCaptureFilePath:_screenCaptureFilePath andAudio:_audioRecordFilePath andTarget:self andAction:@selector(outputVideoWithMergeViedoPath:)];
}
- (void)captureFailWithError:(NSError *)error{
    [self screenRecordStop];
    if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingFailedWithError:)]) {
        [self.delegate screenRecordingFailedWithError:error];
    }
}
#pragma mark ---KWAudioRecordDelegate
- (void)audioRecordCompletedWithAudioRecordFilePath:(id)audioRecordFilePath{
    _audioRecordFilePath = audioRecordFilePath;
}

- (void)outputVideoWithMergeViedoPath:(NSString *)mergeVieoPath{
    if (self.recordingStatus == KWScreenRecordingStatusNormal) {
        NSLog(@"stop mergeVieoPath === %@",mergeVieoPath);
        if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingCompleteWithScreenRecordingFilePath:)]) {
            [self.delegate screenRecordingCompleteWithScreenRecordingFilePath:mergeVieoPath];
        }
    }else{
        NSLog(@"pause mergeVieoPath === %@",mergeVieoPath);
    }
}

#pragma mark ---懒加载
- (KWScreenCapture *)screenCapture{
    if (nil == _screenCapture) {
        _screenCapture = [KWScreenCapture new];
        _screenCapture.delegate = self;
    }
    return _screenCapture;
}
- (KWAudioRecord *)audioRecord{
    if (nil == _audioRecord) {
        _audioRecord = [KWAudioRecord new];
        _audioRecord.delegate = self;
    }
    return _audioRecord;
}

@end
