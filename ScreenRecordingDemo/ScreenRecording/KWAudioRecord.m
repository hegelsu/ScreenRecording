//
//  KWAudioRecord.m
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//

#import "KWAudioRecord.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/CoreAudioKit.h>

static NSString *const kwScreenCaptureFileName = @"audioRecord.wav";
@interface KWAudioRecord ()

@property (nonatomic,strong)AVAudioRecorder *recorder;

@end

@implementation KWAudioRecord

#pragma mark ----废弃对象
- (void)dealloc{
    if (self.recorder.isRecording) {
        [self.recorder stop];
        self.recorder = nil;
    }
}

#pragma mark - 开始录音
- (void)startRecord{
    NSLog(@"startRecord");
    //clean old file
    NSError  *error = nil;
    NSString *filePath=[self audioRecordFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]){
        if ([fileManager removeItemAtPath:filePath error:&error] == NO){
            NSLog(@"KWScreenRecording Could not delete old recording file at path:  %@", filePath);
        }
    }
    //初始化录音
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:[self audioRecordFilePath]] settings:[self getAudioRecorderSettingDict] error:nil];
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    //开始录音
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.recorder record];
}
- (void)stopRecord{
    NSLog(@"stopRecord");
    if (self.recorder.isRecording) {
        [self.recorder stop];
        self.recorder = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecordCompletedWithAudioRecordFilePath:)]) {
            [self.delegate audioRecordCompletedWithAudioRecordFilePath:[self audioRecordFilePath]];
        }
    }
}

- (void)clean{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self audioRecordFilePath]]){
        [[NSFileManager defaultManager] removeItemAtPath:[self audioRecordFilePath] error:nil];
    }
}

- (NSDictionary*)getAudioRecorderSettingDict{
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:8000.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt:1], AVNumberOfChannelsKey,//通道的数目
                                   nil];
    return recordSetting;
}
- (NSString*)audioRecordFilePath{
    if (self.audioPath) {
        return self.audioPath;
    }else{
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:kwScreenCaptureFileName];
        return filePath;
    }
}

@end
