//
//  WZMatrixMixerEngine.m
//  WZAudioUnitTest
//
//  Created by admin on 5/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//


#import "WZMatrixMixerEngine.h"
#import "CAStreamBasicDescription.h"


/***
 暂时不知道哪里出了问题
 **/

typedef struct {
    AudioStreamBasicDescription asbd;           //ID
    float *data;                                //数据
    UInt32 numFrames;                           //总帧数
    UInt32 phase;                               //样本号
    NSString *name;                             //URL。path？
} SoundBuffer;///bus数据结构体系

const int MaxBus = 8;//记得在sof上说过是一个bug还是什么限定，最大只能设置8个bus
const Float64 SampleRate = 44100.0;
//全局结构体
struct SynthData {
    int numbufs;////数目 根据文件
    SoundBuffer bufs[MaxBus];//bus的总数
    int select;
};


@interface WZMatrixMixerEngine()
{
    SynthData data;
    
    AUGraph graph;
    AudioUnit mixerUnit;
}

@end

@implementation WZMatrixMixerEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        memset(&data, 0, sizeof(data));//内存设置为0
        [self configFile];
        [self configGraph];
         CheckError(AUGraphStart(graph), "start!");
       
    }
    return self;
}


- (void)configFile {
    NSArray <NSURL *>* urlArr = @[
//                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"祝君好" ofType:@"mp3"]],
//                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Loveless" ofType:@"mp3"]]
                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"DrumsMonoSTP" ofType:@"aif"]],
                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GuitarMonoSTP" ofType:@"aif"] ]
                                  ];
#warning 使用mp3格式时，数据有点问题
    
    ///bus数目
    data.numbufs = (int)urlArr.count;
    //清理缓存
    for (int i = 0; i < MaxBus; i++) {
        if (data.bufs[i].data) {
            free(data.bufs[i].data);
            data.bufs[i].data = 0;
        }
        if (data.bufs[i].name) {
            data.bufs[i].name = 0;
        }
    }
    
    //写入buffer
    for (int i = 0; i < data.numbufs; i++) {
        ExtAudioFileRef xafref;
        CheckError(ExtAudioFileOpenURL((__bridge CFURLRef)urlArr[i], &xafref), "openURL");
        
        AudioStreamBasicDescription fileDataFormat;
        UInt32 propSize = sizeof(fileDataFormat);
        CheckError(ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileDataFormat), "getFormate");
        
         //2个通道。交叉音频为true
        CAStreamBasicDescription clientFormat = CAStreamBasicDescription(SampleRate, 2, CAStreamBasicDescription::kPCMFormatFloat32, true);
        propSize = sizeof(clientFormat);
        //设置格式
        CheckError(ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat), "setFormate");
        
        propSize = sizeof(UInt64);
        UInt32 numFrames = 0;
        CheckError( ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames), "getProperty");
        
        
        ///适配速率
        double rateRatio = SampleRate / fileDataFormat.mSampleRate;
        numFrames = (UInt32)(numFrames * rateRatio);
        
        data.bufs[i].numFrames = (UInt32)numFrames;
        data.bufs[i].asbd = clientFormat;
        data.bufs[i].name = urlArr[i].path;
        
        UInt32 samples = (UInt32)numFrames * data.bufs[i].asbd.mChannelsPerFrame;
        data.bufs[i].data = (float*)calloc(samples, sizeof(Float32));
        data.bufs[i].phase = 0;
        
        AudioBufferList ABL;
        ABL.mNumberBuffers = 1;
        ABL.mBuffers[0].mNumberChannels = 2;
        ABL.mBuffers[0].mData = data.bufs[i].data;
        ABL.mBuffers[0].mDataByteSize = samples * sizeof(Float32);
        
        UInt32 numPackets = numFrames;
        if (ExtAudioFileRead(xafref, &numPackets, &ABL)) {
            free(data.bufs[i].data);
            data.bufs[i].data = 0;
        }
        ExtAudioFileDispose(xafref);
    }
}


- (void)configGraph  {
    CheckError(NewAUGraph(&graph), __func__);
    
    AUNode mixerNode = 0, outputNode;
    AudioComponentDescription ACD = {};
    ACD.componentFlags = 0;
    ACD.componentFlagsMask = 0;
    ACD.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    ACD.componentType = kAudioUnitType_Output;
    ACD.componentSubType = kAudioUnitSubType_RemoteIO;
//    ACD.componentFlags = kAudioComponentFlag_SandboxSafe;
    CheckError(AUGraphAddNode(graph, &ACD, &outputNode), "node");
    
    ACD.componentType = kAudioUnitType_Mixer;
    ACD.componentSubType = kAudioUnitSubType_MatrixMixer;
    
//    ACD.componentFlags = kAudioComponentFlag_SandboxSafe;
    CheckError(AUGraphAddNode(graph, &ACD, &mixerNode), "node");
    
    CheckError(AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0), "input");
    
    CheckError(AUGraphOpen(graph), "open");
    
    CheckError(AUGraphNodeInfo(graph, mixerNode, NULL, &mixerUnit), "nodeInfo");
    
////属性
    UInt32 size;
    UInt32 enable = 1;
    //开启测量模式
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Global, 0, &enable, sizeof(enable)), "_MeteringMode");//启用或禁用对特定scope/element的测量
    
    UInt32 busNumber = 2;
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busNumber, sizeof(UInt32)), "_ElementCount");// inpute scope
    busNumber = 1;
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Output, 0, &busNumber, sizeof(UInt32)), "_ElementCount");
    ///2进1出
    
    CAStreamBasicDescription desc;
    busNumber = 2;
    for (UInt32 i = 0; i < busNumber; i++) {
        AURenderCallbackStruct renderCallBack = {};
        renderCallBack.inputProc = renderCall;
        renderCallBack.inputProcRefCon = &data;////注意 引用的是全局结构体
        
        CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &renderCallBack, sizeof(renderCallBack)), "_SetRenderCallback");
      
        size = sizeof(desc);
        //查看
        CheckError(AudioUnitGetProperty(mixerUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        i,
                                        &desc,
                                        &size), "GetProperty");
        
        //修改通道数目
        desc.ChangeNumberChannels(2, false);////修改通道数目为2
        desc.mSampleRate = SampleRate;
        CheckError(AudioUnitSetProperty(mixerUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,//input channel
                                        i,
                                        &desc,
                                        sizeof(desc)), "SetProperty");
    }
    
    CheckError(AudioUnitGetProperty(mixerUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &desc,
                                    &size), "GetProperty");
    desc.ChangeNumberChannels(2, false);////修改通道数目为2
    desc.mSampleRate = SampleRate;
    CheckError(AudioUnitSetProperty(mixerUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &desc,
                                    sizeof(desc)), "SetProperty");
    
    CheckError(AUGraphInitialize(graph), "graphInitialize");
    CAShow(graph);
    
    
////没有半点声音
    AudioUnitParameterValue value;

    CheckError( AudioUnitSetParameter(mixerUnit, kMatrixMixerParam_Enable, kAudioUnitScope_Input, 0, 1, 0), "sdadassdasd");

    CheckError(AudioUnitSetParameter(mixerUnit, kMatrixMixerParam_Enable, kAudioUnitScope_Output, 0, 1, 0), "dasdasdsadsadad");

    CheckError(AudioUnitGetParameter(mixerUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0xFFFFFFFF, &value), "volume");

    CheckError(AudioUnitSetParameter(mixerUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0, 1, 0), "setVolume");

    CheckError(AudioUnitSetParameter(mixerUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0, 1, 0), "vsadasdasd");

    CheckError(AudioUnitSetParameter(mixerUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Output, 0, 1, 0), "sadasdasd");
 
}

static OSStatus renderCall (    void *                            inRefCon,
                            AudioUnitRenderActionFlags *    ioActionFlags,
                            const AudioTimeStamp *            inTimeStamp,
                            UInt32                            inBusNumber,
                            UInt32                            inNumberFrames,
                            AudioBufferList * __nullable    ioData) {
    SynthData& d = *(SynthData*)inRefCon;
    UInt32 bufSamples = d.bufs[inBusNumber].numFrames << 1;///左移
    Float32 *in = d.bufs[inBusNumber].data;
    
    Float32 *outA = (Float32*)ioData->mBuffers[0].mData;
    Float32 *outB = (Float32*)ioData->mBuffers[1].mData;
    if (!in) {
        for (UInt32 i=0; i<inNumberFrames; ++i)
        {
            outA[i] = 0.f;
            outB[i] = 0.f;
        }
    } else {
        UInt32 phase = d.bufs[inBusNumber].phase;
        for (UInt32 i=0; i<inNumberFrames; ++i)
        {
            outA[i] = in[phase++];
            outB[i] = in[phase++];
            if (phase >= bufSamples) phase = 0;
//            NSLog(@"%f", (Float32)outA[i]);
//            NSLog(@"%f", (Float32)outB[i]);
        }
        d.bufs[inBusNumber].phase = phase;
    }
    
    return noErr;
}


#pragma mark - Public
- (void)stop {
    AUGraphStop(graph);
}
@end
