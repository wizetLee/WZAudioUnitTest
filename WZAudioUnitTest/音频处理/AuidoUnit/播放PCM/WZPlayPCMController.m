//
//  WZPCMPlayerController.m
//  WZAudioUnitTest
//
//  Created by admin on 5/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "WZPlayPCMController.h"
#import "PCMPlayer.h"

@interface WZPlayPCMController ()<PCMPlayerProtocol>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) PCMPlayer *player;

@end

@implementation WZPlayPCMController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)playAction:(UIButton *)sender {
    sender.hidden = true;
    _player = [PCMPlayer new];
    _player.delegate = self;
    [_player play];
}

- (void)dealloc {
    [self playFinished];
}

#pragma mark - PCMPlayerProtocol
#pragma mark - PCMPlayerProtocol

- (void)playFinished {
    _playButton.hidden = false;
    _player.delegate = nil;
    _player = nil;
}

@end
