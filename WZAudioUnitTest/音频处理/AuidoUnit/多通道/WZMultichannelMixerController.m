//
//  WZMultichannelMixerController.m
//  WZWeather
//
//  Created by admin on 4/1/18.
//  Copyright © 2018年 WZ. All rights reserved.
//

#import "WZMultichannelMixerController.h"
#import "WZMultichannelMixerEngine.h"

@interface WZMultichannelMixerController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UISlider *lChannelVolumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *rChannelVolumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *outputVolumeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *lChannelEnableSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rChannelEnableSwitch;

@property (nonatomic, strong) WZMultichannelMixerEngine *mixerEngine;

@end

@implementation WZMultichannelMixerController

-(void)dealloc {
    [_mixerEngine stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setPreferredIOBufferDuration:0.005 error:&error];
    [session setPreferredSampleRate:44100.0 error:&error];
    [session setActive:true error:&error];
    
    _mixerEngine = WZMultichannelMixerEngine.alloc.init;
    [_mixerEngine configFiles];
    [_mixerEngine configGraph];
    _lChannelEnableSwitch.on = true;
    _rChannelEnableSwitch.on = true;
    _lChannelVolumeSlider.value = 0.5;
    _rChannelVolumeSlider.value = 0.5;
    _outputVolumeSlider.value = 1.0;
    
    [self adjustVolumeAction:_lChannelVolumeSlider];
    [self adjustVolumeAction:_rChannelVolumeSlider];
    [self adjustVolumeAction:_outputVolumeSlider];
    
    [self channelVolumeEnableAction:_rChannelEnableSwitch];
    [self channelVolumeEnableAction:_lChannelEnableSwitch];
    
}

- (IBAction)adjustVolumeAction:(UISlider *)sender {
    UInt32 busNum = 0;
    if (sender == _rChannelVolumeSlider) {
        busNum = 1;
    } else if (sender == _lChannelVolumeSlider) {
        
    } else {
        [_mixerEngine setOutputBusVolume:sender.value];
        return;
    }
    [_mixerEngine setBusInput:busNum volume:sender.value];
}



- (IBAction)channelVolumeEnableAction:(UISwitch *)sender {
    UInt32 busNum = 0;
    if (sender == _rChannelEnableSwitch) {
        busNum = 1;
    }
    [_mixerEngine enableBusInput:busNum isOn:sender.on];
}


- (IBAction)playOrStopAction:(UIButton *)sender {
    [_mixerEngine play];
}

@end
