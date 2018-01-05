//
//  WZMultichannelMixerEngine.h
//  WZWeather
//
//  Created by admin on 4/1/18.
//  Copyright © 2018年 WZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@protocol WZMultichannelMixerEngineProtocol<NSObject>//bla~bla~bla

@end

@interface WZMultichannelMixerEngine : NSObject

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isEffecting;

- (void)withEffect:(BOOL)boolean;

- (void)play;
- (void)stop;
- (void)replay;

///控制mixerUnit某个input bus是否可用配置
- (void)enableBusInput:(UInt32)busInputNumber isOn:(AudioUnitParameterValue)isOn;
//控制mixerUnit input bus的音量
- (void)setBusInput:(UInt32)busInputNumber volume:(AudioUnitParameterValue)volume;
//控制mixerUnit output bus的音量
- (void)setOutputBusVolume:(AudioUnitParameterValue)volume;


@end
