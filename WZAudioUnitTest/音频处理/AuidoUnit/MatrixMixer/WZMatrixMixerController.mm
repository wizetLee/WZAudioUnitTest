//
//  WZMatrixMixerController.m
//  WZAudioUnitTest
//
//  Created by admin on 5/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "WZMatrixMixerController.h"
#import "WZMatrixMixerEngine.h"

@interface WZMatrixMixerController ()

@property (nonatomic, strong) WZMatrixMixerEngine *maxerEngine;

@end

@implementation WZMatrixMixerController

- (void)dealloc {
    [_maxerEngine stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSession];
    
    _maxerEngine = WZMatrixMixerEngine.alloc.init;
    
}

- (void)configSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setActive:true error:&error];
}

@end
