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
@property (weak, nonatomic) IBOutlet UIButton *withEffectButton;

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setActive:true error:&error];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addNotification];
    [self configSession];
    
    _mixerEngine = WZMultichannelMixerEngine.alloc.init;
  
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
- (IBAction)withEffectAction:(UIButton *)sender {
    [_mixerEngine withEffect:!_mixerEngine.isEffecting];
    sender.selected = _mixerEngine.isEffecting;
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
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
    
    if (_mixerEngine.isPlaying) {
        [_mixerEngine stop];
        [self played];
    } else {
        [_mixerEngine play];
        [self stopped];
    }
}

- (IBAction)replay:(id)sender {
    [_mixerEngine replay];
    [self stopped];
}

#pragma mark - notification
- (void)audioSessionInterruptionNotification:(NSNotification *)ntf {
    [_mixerEngine stop];
}

- (void)audioSessionRouteChangeNotification:(NSNotification *)ntf {
    UInt8 reasonValue = [[ntf.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [ntf.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
}

#pragma mark - UI
- (void)played {
    _playButton.selected = false;
}

- (void)stopped {
    _playButton.selected = true;
}

@end
