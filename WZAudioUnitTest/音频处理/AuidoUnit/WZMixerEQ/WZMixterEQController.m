//
//  WZMixterEQController.m
//  WZAudioUnitTest
//
//  Created by admin on 8/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "WZMixterEQController.h"
#import "WZMixterEQEngine.h"

@interface WZMixterEQController ()

@property (nonatomic, strong) WZMixterEQEngine *engine;

@end

@implementation WZMixterEQController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSession];
    
    _engine = WZMixterEQEngine.alloc.init;
    
}

- (void)configSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    NSTimeInterval bufferDuration = .005;
    [session setPreferredIOBufferDuration:bufferDuration error:&error];
    double hwSampleRate = 44100.0;
    [session setPreferredSampleRate:hwSampleRate error:&error];
    [session setActive:true error:&error];
}

- (void)dealloc {
    [_engine stop];
}

@end
