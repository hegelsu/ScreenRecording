//
//  ViewController.m
//  ScreenRecordingDemo
//
//  Created by Springer on 2019/11/5.
//  Copyright © 2019 kuwo. All rights reserved.
//

#import "ViewController.h"
#import "KWScreenRecordingManager.h"

@interface ViewController ()<KWScreenRecordingManagerDelegate>

@property (nonatomic,strong)KWScreenRecordingManager *recordingManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    // Do any additional setup after loading the view.
    UIImageView *iv = [UIImageView new];
    iv.frame = self.view.bounds;
    iv.image = [UIImage imageNamed:@"image@2x.jpeg"];
    iv.userInteractionEnabled = NO;
    [self.view addSubview:iv];
    
    UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [startBtn setFrame:CGRectMake(0, 50, 100, 40)];
    [startBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [startBtn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    
    UIButton *pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [pauseBtn setFrame:CGRectMake(120, 50, 100, 40)];
    [pauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
    [pauseBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [pauseBtn addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pauseBtn];
    
    UIButton *resumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [resumeBtn setFrame:CGRectMake(0, 120, 100, 40)];
    [resumeBtn setTitle:@"继续" forState:UIControlStateNormal];
    [resumeBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [resumeBtn addTarget:self action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resumeBtn];
    
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopBtn setFrame:CGRectMake(120, 120, 100, 40)];
    [stopBtn setTitle:@"stop" forState:UIControlStateNormal];
    [stopBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
    
    UIButton *cleanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cleanBtn setFrame:CGRectMake(120, 240, 100, 40)];
    [cleanBtn setTitle:@"clean" forState:UIControlStateNormal];
    [cleanBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [cleanBtn addTarget:self action:@selector(clean) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cleanBtn];
    
}

- (void)start{
    [self.recordingManager screenRecordStart];
}
- (void)pause{
    [self.recordingManager screenRecordPause];
}
- (void)resume{
    [self.recordingManager screenRecordResume];
}
- (void)stop{
    [self.recordingManager screenRecordStop];
}
- (void)clean{
    
}

#pragma mark
- (void)screenRecordingCompleteWithScreenRecordingFilePath:(NSString *)screenRecordingFilePath{
    NSLog(@"screenRecordingFilePath %@",screenRecordingFilePath);
}
- (void)screenRecordingFailedWithError:(NSError *)error{
    NSLog(@"screenRecordingFailedWithError  %@",error.localizedDescription);
    
}

- (KWScreenRecordingManager *)recordingManager{
    if (nil == _recordingManager) {
        _recordingManager = [KWScreenRecordingManager shareManager];
        _recordingManager.delegate = self;
        _recordingManager.frameRate = 25;
        _recordingManager.spaceTime = 0.2;
        _recordingManager.captureLayer = self.view.layer;
    }
    return _recordingManager;
}

@end
