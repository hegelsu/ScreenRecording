//
//  KWScreenCapture.m
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//

#import "KWScreenCapture.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

static NSString *const kwScreenCaptureFileName = @"screenCapture.mp4";

@interface KWScreenCapture ()

@property (nonatomic,strong)AVAssetWriter *videoWriter;
@property (nonatomic,strong)AVAssetWriterInput *videoWriterInput;
@property (nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor *videoWriterAdaptor;

@property (nonatomic,assign)BOOL capturing;//正在录制中
@property (nonatomic,assign)BOOL writing;//正在将帧写入文件
@property (nonatomic,strong)NSDate *startedTime;//录制的开始时间
@property (nonatomic,assign)CGContextRef context;//绘制layer的context
@property (nonatomic,strong)NSTimer *timer;//定时器

@end

@implementation KWScreenCapture

#pragma mark ---初始化对象
- (id)init{
    self = [super init];
    if (self) {
        self.frameRate = 25;//默认帧率为25
    }
    return self;
}
#pragma mark ----废弃对象
- (void)dealloc{
    [self cleanupWriter];
}

#pragma mark  ---流程
- (void)startCapture{
    NSLog(@"startCapture");
    //没有绘制层
    if (!self.captureLayer) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureFailWithError:)]) {
            [self.delegate captureFailWithError:[NSError errorWithDomain:@"no capture layer" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no capture layer"}]];
        }
        return;
    }
    //正在捕捉中
    if (self.capturing) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureFailWithError:)]) {
            [self.delegate captureFailWithError:[NSError errorWithDomain:@"is capturing" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"is capturing"}]];
        }
        NSLog(@"capturing");
        return;
    }
    //配置失败
    if (![self setUpWriter]) {
        NSLog(@"setUpWriter error");
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureFailWithError:)]) {
            [self.delegate captureFailWithError:[NSError errorWithDomain:@"setup writer error" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"setup writer error"}]];
        }
        return;
    }
    
    self.startedTime = [NSDate date];
    self.spaceTime = 0.2;
    self.capturing = YES;
    self.writing = NO;
    //绘屏的定时器
    NSDate *nowDate = [NSDate date];
    self.timer = [[NSTimer alloc] initWithFireDate:nowDate interval:1.0 / self.frameRate target:self selector:@selector(drawFrame) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
//配置录制环境
-(BOOL)setUpWriter{
    NSLog(@"setUpWriter");
    NSError  *error = nil;
    NSString *filePath=[self screenCaptureFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]){
        if ([fileManager removeItemAtPath:filePath error:&error] == NO){
            NSLog(@"KWScreenRecording Could not delete old recording file at path:  %@", filePath);
            return NO;
        }
    }
    //Configure videoWriter
    NSURL *fileUrl=[NSURL fileURLWithPath:filePath];
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(self.videoWriter);
    
    CGSize size = self.captureLayer.frame.size;
    //Configure videoWriterInput rateBit
    NSDictionary *videoCompressionProps = @{
        AVVideoAverageBitRateKey:[NSNumber numberWithDouble:size.width * size.height * 4]
    };
    NSDictionary *videoSettings = nil;
    
    if (@available(iOS 11.0, *)) {
        videoSettings = @{
            AVVideoCodecKey:AVVideoCodecTypeH264,
            AVVideoWidthKey:[NSNumber numberWithInt:size.width],
            AVVideoHeightKey:[NSNumber numberWithInt:size.height],
            AVVideoCompressionPropertiesKey:videoCompressionProps
        };
    } else {
        videoSettings = @{
            AVVideoCodecKey:AVVideoCodecH264,
            AVVideoWidthKey:[NSNumber numberWithInt:size.width],
            AVVideoHeightKey:[NSNumber numberWithInt:size.height],
            AVVideoCompressionPropertiesKey:videoCompressionProps
        };
    }
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(self.videoWriterInput);
    
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary *bufferAttributes = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB]};
    
    self.videoWriterAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
    
    //add input
    [self.videoWriter addInput:self.videoWriterInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
    //create context
    if (self.context == NULL){
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        self.context = CGBitmapContextCreate (NULL,
                                         size.width,
                                         size.height,
                                         8,//bits per component
                                         size.width *4,
                                         colorSpace,
                                         kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
        CGContextSetAllowsAntialiasing(self.context,NO);
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0,-1, 0, size.height);
        CGContextConcatCTM(self.context, flipVertical);
    }
    if (self.context == NULL){
        fprintf (stderr, "Context not created!");
        return NO;
    }
    return YES;
}
- (void)drawFrame{
    NSLog(@"drawFrame");
    if (!self.writing) {
        [self performSelectorInBackground:@selector(getFrame) withObject:nil];
    }
}
- (void)getFrame{
    NSLog(@"getFrame");
    if (!self.writing) {
        self.writing = true;
        size_t width  = CGBitmapContextGetWidth(self.context);
        size_t height = CGBitmapContextGetHeight(self.context);
        @try {
            CGContextClearRect(self.context, CGRectMake(0, 0,width , height));
            [self.captureLayer renderInContext:self.context];
            self.captureLayer.contents=nil;
            CGImageRef cgImage = CGBitmapContextCreateImage(self.context);
            if (self.capturing) {
                float millisElapsed = [[NSDate date] timeIntervalSinceDate:self.startedTime] * 1000.0 - self.spaceTime * 1000.0;
                [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000) addImage:cgImage];
            }
            CGImageRelease(cgImage);
        }
        @catch (NSException *exception) {
        }
        self.writing = NO;
    }
}
-(void)writeVideoFrameAtTime:(CMTime)time addImage:(CGImageRef)newImage{
    NSLog(@"writeVideoFrameAtTime");
    if (![self.videoWriterInput isReadyForMoreMediaData]) {
        NSLog(@"Not ready for video data");
    }else {
        @synchronized (self) {
            CVPixelBufferRef pixelBuffer = NULL;
            CGImageRef cgImage = CGImageCreateCopy(newImage);
            CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
            
            CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self.videoWriterAdaptor.pixelBufferPool, &pixelBuffer);
            if(status != kCVReturnSuccess){
                //could not get a buffer from the pool
                NSLog(@"Error creating pixel buffer:  status=%d", status);
                return;
            }
            // set image data into pixel buffer
            CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
            uint8_t *destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
            CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);
            if(status == 0){
                BOOL success = [self.videoWriterAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                if (!success)
                    NSLog(@"Warning:  Unable to write buffer to video");
            }
            //clean up
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CVPixelBufferRelease(pixelBuffer );
            CFRelease(image);
            CGImageRelease(cgImage);
        }
    }
}
- (void)stopCapture{
    NSLog(@"stopCapture");
    if (self.capturing) {
        self.capturing = NO;
        [self.timer invalidate];
        self.timer = nil;
        [self completeRecordingSession];
        [self cleanupWriter];
    }
}
- (void)completeRecordingSession{
    NSLog(@"completeRecordingSession");
    [self.videoWriterInput markAsFinished];
    // Wait for the video
    AVAssetWriterStatus status = self.videoWriter.status;
    while (status == AVAssetWriterStatusUnknown){
        NSLog(@"Waiting...");
        [NSThread sleepForTimeInterval:0.2f];
        status = self.videoWriter.status;
    }
    __weak typeof(self) weakSelf = self;
    [self.videoWriter finishWritingWithCompletionHandler:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        NSLog(@"Completed recording, file is stored at:  %@", [strongSelf screenCaptureFilePath]);
        if ([strongSelf.delegate respondsToSelector:@selector(captureCompletedWithScreenCaptureFilePath:)]) {
            [strongSelf.delegate captureCompletedWithScreenCaptureFilePath:[self screenCaptureFilePath]];
        }
    }];
}
- (void)cleanupWriter{
    self.videoWriterAdaptor = nil;
    self.videoWriterInput = nil;
    self.videoWriter = nil;
    self.startedTime = nil;
}

- (void)clean{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self screenCaptureFilePath]]){
        [[NSFileManager defaultManager] removeItemAtPath:[self screenCaptureFilePath] error:nil];
    }
}
#pragma mark ----存储路径
- (NSString*)screenCaptureFilePath{
    if (self.capturePath) {
        return self.capturePath;
    }else{
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:kwScreenCaptureFileName];
        return filePath;
    }
}

@end
