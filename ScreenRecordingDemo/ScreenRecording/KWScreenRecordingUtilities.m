//
//  KWScreenRecordingUtilities.m
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//

#import "KWScreenRecordingUtilities.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

static NSString *const kwScreenRecordingMergeVideoName = @"mergeVideo.mp4";
static NSString *const kwScreenRecordingOutputVideoName = @"output.mp4";

@implementation KWScreenRecordingUtilities

/// 合成视频
/// @param screenCaptureFilePath 屏幕捕捉文件路径
/// @param audioPath 录音文件路径
/// @param target <#target description#>
/// @param action <#action description#>
+ (void)mergeVideoWithScreenCaptureFilePath:(NSString *)screenCaptureFilePath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action{
    NSURL *audioUrl=[NSURL fileURLWithPath:audioPath];
    NSURL *videoUrl=[NSURL fileURLWithPath:screenCaptureFilePath];
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    //混合音乐
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)
                                        ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                         atTime:kCMTimeZero error:nil];
    //混合视频
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:kCMTimeZero error:nil];
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeMPEG4;
    //保存混合后的文件的过程
    NSString *mergeVideoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:kwScreenRecordingMergeVideoName];
    NSURL *exportUrl = [NSURL fileURLWithPath:mergeVideoPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:mergeVideoPath]){
        [[NSFileManager defaultManager] removeItemAtPath:mergeVideoPath error:nil];
    }
    NSLog(@"file type %@",assetExport.outputFileType);
    assetExport.outputURL = exportUrl;
    assetExport.shouldOptimizeForNetworkUse = YES;
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ){
        NSLog(@"完成了");
        if ([[NSFileManager defaultManager] fileExistsAtPath:screenCaptureFilePath]){
            [[NSFileManager defaultManager] removeItemAtPath:screenCaptureFilePath error:nil];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath]){
            [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
        }
        [self outputVideoWithMergeVideoPath:mergeVideoPath andTarget:target andAction:action];
    }];
}

+ (void)outputVideoWithMergeVideoPath:(NSString *)mergeVideoPath andTarget:(id)target andAction:(SEL)action{
    NSString *outputVideoPath=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",kwScreenRecordingOutputVideoName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputVideoPath]) {//有残留视频  做视频合并
        if ([[NSFileManager defaultManager] fileExistsAtPath:mergeVideoPath]){
            [self combVideosWithCombVideoPath:mergeVideoPath outputVideoPath:outputVideoPath andBlock:^{
                if (target && [target respondsToSelector:action]){
                    [target performSelector:action withObject:outputVideoPath withObject:nil];
                }
            }];
        }
    }else{
        if ([[NSFileManager defaultManager] fileExistsAtPath:mergeVideoPath]){
            NSError *err=nil;
            if ([[NSFileManager defaultManager] moveItemAtPath:mergeVideoPath toPath:outputVideoPath error:&err]) {
                if (target && [target respondsToSelector:action]){
                    [target performSelector:action withObject:outputVideoPath withObject:nil];
                }
            }
        }
    }
    
}

/// 合并视频
/// @param combVideoPath 合并的食品
/// @param outputVideoPath 残存食品
/// @param block <#block description#>
+ (void)combVideosWithCombVideoPath:(NSString *)combVideoPath outputVideoPath:(NSString *)outputVideoPath andBlock:(void(^)(void))block{
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:outputVideoPath] options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:combVideoPath] options:optDict];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    //由于没有计算当前CMTime的起始位置，现在插入0的位置,所以合并出来的视频是后添加在前面，可以计算一下时间，插入到指定位置
    //CMTimeRangeMake 指定起去始位置
    CMTimeRange firstTimeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    CMTimeRange secondTimeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration);
    
    //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
    //添加音频,添加本地其他音乐也可以,与视频一致
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:secondTimeRange ofTrack:[secondAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    [audioTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    
    //为视频类型的的Track
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionTrack insertTimeRange:secondTimeRange ofTrack:[secondAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    [compositionTrack insertTimeRange:firstTimeRange ofTrack:[firstAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [cachePath stringByAppendingPathComponent:@"comp.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];//  AVAssetExportPresetHighestQuality  AVAssetExportPresetPassthrough
    exporterSession.outputFileType = AVFileTypeMPEG4;//AVFileTypeMPEG4  AVFileTypeMPEG4
    exporterSession.outputURL = [NSURL fileURLWithPath:filePath]; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exporterSession.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                    NSError *err=nil;
                    if ([[NSFileManager defaultManager] fileExistsAtPath:outputVideoPath]){
                        [[NSFileManager defaultManager] removeItemAtPath:outputVideoPath error:nil];
                    }
                    [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:outputVideoPath error:&err];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:combVideoPath]){
                        [[NSFileManager defaultManager] removeItemAtPath:combVideoPath error:nil];
                    }
//                    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
//                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//                    }
                    if (block) {
                        block();
                    }
                }
                break;
        }
    }];
}

+ (void)clean{
    NSString *path=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",kwScreenRecordingOutputVideoName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {//有残留视频  做视频合并
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
}

@end
