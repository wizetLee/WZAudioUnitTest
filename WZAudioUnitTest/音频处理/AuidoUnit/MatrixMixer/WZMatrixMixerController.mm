//
//  WZMatrixMixerController.m
//  WZAudioUnitTest
//
//  Created by admin on 5/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "WZMatrixMixerController.h"


@interface WZMatrixMixerController ()

@end

@implementation WZMatrixMixerController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSession];
}

- (void)configSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setActive:true error:&error];
}

@end
