//
//  WZMatrixMixerEngine.m
//  WZAudioUnitTest
//
//  Created by admin on 5/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "CAStreamBasicDescription.h"
#import "WZMatrixMixerEngine.h"

@interface WZMatrixMixerEngine()
{
    AUGraph graph;
    AudioUnit mixerUnit;
}

@end

@implementation WZMatrixMixerEngine

- (void)configGraph  {
    CheckError(NewAUGraph(&graph), __func__);
    
    AUNode mixerNode = 0, outputNode;
    AudioComponentDescription ACD = {};
    ACD.componentFlags = 0;
    ACD.componentFlagsMask = 0;
    ACD.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    ACD.componentType = kAudioUnitType_Output;
    ACD.componentSubType = kAudioUnitSubType_RemoteIO;
    AUGraphAddNode(graph, &ACD, &outputNode);
    
    ACD.componentType = kAudioUnitType_Mixer;
    ACD.componentSubType = kAudioUnitSubType_MatrixMixer;
    AUGraphAddNode(graph, &ACD, &mixerNode);
    
    AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0);
    
    AUGraphOpen(graph);
    
    AUGraphNodeInfo(graph, mixerNode, NULL, &mixerUnit);
    
////属性
    UInt32 size;
    UInt32 enable = 1;
    //开启测量
    AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Global, 0, &enable, sizeof(enable));//启用或禁用对特定scope/element的测量
    
    
    UInt32 busNumber = 2;
    AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Global, 0, &busNumber, sizeof(busNumber));//启用或
    CAStreamBasicDescription desc;
    for (UInt32 i = 0; i < busNumber; i++) {
        AURenderCallbackStruct renderCallBack = {};
        renderCallBack.inputProc = renderCall;
        renderCallBack.inputProcRefCon = (__bridge void * _Nullable)(self);
        
        AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &renderCallBack, sizeof(renderCallBack));
      
    
        size = sizeof(desc);
        //查看
        AudioUnitGetProperty(mixerUnit,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Input,
                             i,
                             &desc,
                             &size);
        
        //修改通道数目
        desc.ChangeNumberChannels(2, false);
        desc.mSampleRate = 44100;
        AudioUnitSetProperty(mixerUnit,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Input,//input channel
                             i,
                             &desc,
                             sizeof(desc));
    }
    
    AudioUnitGetProperty(mixerUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         0,
                         &desc,
                         &size);
    desc.ChangeNumberChannels(5, false);
    desc.mSampleRate = 44100;
    AudioUnitSetProperty(mixerUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         0,
                         &desc,
                         sizeof(desc));
    
    AUGraphInitialize(graph);
    CAShow(graph);
    
    
    
}

static OSStatus renderCall (    void *                            inRefCon,
                            AudioUnitRenderActionFlags *    ioActionFlags,
                            const AudioTimeStamp *            inTimeStamp,
                            UInt32                            inBusNumber,
                            UInt32                            inNumberFrames,
                            AudioBufferList * __nullable    ioData) {
    return noErr;
}

@end
