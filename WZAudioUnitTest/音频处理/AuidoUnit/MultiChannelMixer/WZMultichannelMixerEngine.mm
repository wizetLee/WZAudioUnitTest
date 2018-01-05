//
//  WZMultichannelMixerEngine.m
//  WZWeather
//
//  Created by admin on 4/1/18.
//  Copyright © 2018年 WZ. All rights reserved.
//

#import "WZMultichannelMixerEngine.h"


#define SAMPLERATE 44100.0//[[AVAudioSession sharedInstance] sampleRate]

static const int BusCount = 2;

typedef struct {
    AudioStreamBasicDescription asbd;   //ID
    Float32 *data;                      //实际数据
    UInt32 numFrames;                   //帧数
    UInt32 sampleNum;                   //样本号
} SoundBuffer, *SoundBufferPtr;


@interface WZMultichannelMixerEngine()
{
    AUGraph graph;                          //graph
    AudioUnit mixerUnit;                    //Mixing
    AudioUnit outputUnit;                   //I/O    可有可无
    AudioUnit effectUnit;                   //Effect
    
    SoundBuffer soundBuffer[BusCount];      //结构体数组
    
  
    //node
    AUNode outputNode, mixerNode, effectNode;
}

@end

/**
 若干个inpout bus --->  mixer  ---> effect ----> io
 */
@implementation WZMultichannelMixerEngine


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        memset(&soundBuffer, 0, sizeof(soundBuffer));
        
//        [self configFiles];
        [self performSelectorInBackground:@selector(configFiles) withObject:nil];
        [self configGraph];
    }
    return self;
}

- (void)configFiles {
    //PCM Format
    AVAudioFormat *clientFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:SAMPLERATE channels:1 interleaved:true];
    NSArray <NSURL *>* urlArr = @[
                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"小丑鱼" ofType:@"mp3"]],
                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"敢不敢" ofType:@"mp3"] ]
//                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"DrumsMonoSTP" ofType:@"aif"]],
//                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GuitarMonoSTP" ofType:@"aif"] ]
                                  ];
    
    //bus Count
    for (int i = 0; i < BusCount; i++) {
        ExtAudioFileRef extAFRef = NULL;
        //获得句柄
        
        CheckError(ExtAudioFileOpenURL((__bridge CFURLRef)urlArr[i], &extAFRef), "ExtAudioFileOpenURL");
        //获取格式
        AudioStreamBasicDescription ASBD = {0};
        UInt32 ASBDSize = sizeof(AudioStreamBasicDescription);
        CheckError(ExtAudioFileGetProperty(extAFRef, kExtAudioFileProperty_FileDataFormat, &ASBDSize, &ASBD), "kExtAudioFileProperty_FileDataFormat");
        
//保障格式：取得文件的格式可通过FormatID查看数据类型
    /**
        关于：kExtAudioFileProperty_ClientDataFormat
        （You must set this in order to encode or decode a non-PCM file data format.）
        如果使用到非PCM数据格式的文件，必须通过此键修改数据格式
     */
        CheckError(ExtAudioFileSetProperty(extAFRef, kExtAudioFileProperty_ClientDataFormat, ASBDSize, clientFormat.streamDescription), "ClientDataFormat");
        
        //获取文件帧数
        UInt64 numberOfFramesInFile = 0;
        UInt32 ioPropertyDataSize = sizeof(numberOfFramesInFile);
        CheckError(ExtAudioFileGetProperty(extAFRef, kExtAudioFileProperty_FileLengthFrames, &ioPropertyDataSize, &numberOfFramesInFile), "ClientDataFormat");
        
        //匹配速率
        double rateRatie = SAMPLERATE / ASBD.mSampleRate;
        numberOfFramesInFile = numberOfFramesInFile * rateRatie;//帧率转换最终得到的帧数 setPro
        
        ///buffer 部分 BusCount
        //buffer 创建
        SoundBuffer *bufferStr = &soundBuffer[i];
        (*bufferStr).numFrames = (UInt32)numberOfFramesInFile;
        (*bufferStr).asbd = *clientFormat.streamDescription;
        UInt32 samples = (UInt32)numberOfFramesInFile * (*bufferStr).asbd.mChannelsPerFrame;//通道数 * 帧数
        (*bufferStr).data = (Float32 *)calloc(samples, sizeof(Float32));//创建对应大的空间
        (*bufferStr).sampleNum = 0;
        
        //读取数据到ABL中
        AudioBufferList ABL = {};
        ABL.mNumberBuffers = 1;
        ABL.mBuffers[0].mNumberChannels = 1;
        ABL.mBuffers[0].mDataByteSize = samples * sizeof(UInt32);//字节 2^8
#warning 出错在这里😓 应该关联上这份buffer
//        ABL.mBuffers[0].mData = (Float32 *)calloc(samples, sizeof(Float32));
        ABL.mBuffers[0].mData = soundBuffer[i].data;
        
//大文件卡顿
        //同步按顺序把音频数据从文件中读取到创建的buffer中
        UInt32 numPackets = (UInt32)numberOfFramesInFile;
        if (CheckError(ExtAudioFileRead(extAFRef, &numPackets, &ABL), "ExtAudioFileRead") != noErr) {
            free(soundBuffer[i].data);
            soundBuffer[i].data = 0;
        }
        CheckError(ExtAudioFileDispose(extAFRef), "ExtAudioFileDispose");
    }
}

- (void)configGraph {
    
    if (CheckError(NewAUGraph(&graph), "NewAUGraph(&auGraph)") != noErr) {
        return;
    };
    
    AudioComponentDescription ACD = {0};
    ACD.componentManufacturer     = kAudioUnitManufacturer_Apple;
    ACD.componentFlags            = 0;
    ACD.componentFlagsMask        = 0;
    
    
//get node
    //IO
    ACD.componentType             = kAudioUnitType_Output;
    ACD.componentSubType          = kAudioUnitSubType_RemoteIO;
    CheckError(AUGraphAddNode(graph, &ACD, &outputNode), "outputNode");
    
    //mixer
    ACD.componentType             = kAudioUnitType_Mixer;
    ACD.componentSubType          = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode(graph, &ACD, &mixerNode), "outputNode");
    
    //effect
    ACD.componentType             = kAudioUnitType_Effect;
    ACD.componentSubType          = kAudioUnitSubType_Delay;
    CheckError(AUGraphAddNode(graph, &ACD, &effectNode), "effectNode");
    
    
    //connect a node's output to a node's input
    AUGraphConnectNodeInput(graph, mixerNode, 0/*source node bus*/, outputNode, 0/*desinatation node element*/);
   
    //open graph
    CheckError(AUGraphOpen(graph), "graphOpen");
   
//get unit
    CheckError(AUGraphNodeInfo(graph, mixerNode, NULL, &mixerUnit), "mixerUnit");
    CheckError(AUGraphNodeInfo(graph, effectNode, NULL, &effectUnit), "effectUnit");
    CheckError(AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit), "outputUnit");
    
//////////////////属性配置
 
    //配置input bus 的数目
    UInt32 tmpBusCount = BusCount;
    AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &tmpBusCount, sizeof(tmpBusCount));
    
    //the format for the graph 制定graph的格式
    AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:SAMPLERATE channels:2 interleaved:false];
    //为2个input分发内容
    for (int i = 0; i < tmpBusCount; i++) {
        AURenderCallbackStruct inputCallBack = {};
        inputCallBack.inputProc = renderInput;//处理
        inputCallBack.inputProcRefCon = soundBuffer;//引用
        
        //为指定的node的触发指定input call back 调度 : pull
        CheckError(AUGraphSetNodeInputCallback(graph, mixerNode, i, &inputCallBack), "AUGraphSetNodeInputCallback");
        //等效于
//        CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &inputCallBack, sizeof(inputCallBack)), "SetRenderCallback");
        
        //设置mixerUnit 的input bus 数据流格式
        CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, format.streamDescription, sizeof(AudioStreamBasicDescription)), "_StreamFormat");
    }
    
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, format.streamDescription, sizeof(AudioStreamBasicDescription)), "_StreamFormat");
    
    //格式传递   IO
     CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, format.streamDescription, sizeof(AudioStreamBasicDescription)), "_StreamFormat");
    //或者
//    CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, format.streamDescription, sizeof(AudioStreamBasicDescription)), "_StreamFormat");
    
    //validate connection： 验证链接以及初始化graph
    CheckError(AUGraphInitialize(graph), "AUGraphInitialize");
    
    CAShow(graph);
}

- (void)withEffect:(BOOL)boolean {
    BOOL tmpStatus = self.isPlaying;
#warning 是否存在解决切换connect时不停止graph的方案？
    CheckError(AUGraphStop(graph), __func__);
    
    OSStatus err = noErr;
    if (boolean) {
        _isEffecting = true;
        //Effect
        err = AUGraphDisconnectNodeInput(graph, outputNode, 0);
        err = AUGraphConnectNodeInput(graph, mixerNode, 0, effectNode, 0);
        err = AUGraphConnectNodeInput(graph, effectNode, 0, outputNode, 0);
    } else {
        _isEffecting = false;
        err = AUGraphDisconnectNodeInput(graph, outputNode, 0);
        err = AUGraphDisconnectNodeInput(graph, effectNode, 0);
        err = AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0);
    }
    
    CheckError(err, "error with connect between node！！！！！！！！！！！！！！");
    if (tmpStatus) {
       CheckError(AUGraphStart(graph), "AUGraphStart");
    }
}


#pragma mark - callBack
static OSStatus renderInput(void * inRefCon,
                    AudioUnitRenderActionFlags *    ioActionFlags,
                    const AudioTimeStamp *            inTimeStamp,
                    UInt32                            inBusNumber,
                    UInt32                            inNumberFrames,
                    AudioBufferList * __nullable    ioData) {
    
    SoundBufferPtr sndbuf = (SoundBufferPtr)inRefCon;       //两份缓存
    //根据bus获得对应的信息
    UInt32 sample = sndbuf[inBusNumber].sampleNum;          //样本号
    UInt32 bufSamples = sndbuf[inBusNumber].numFrames;      //总帧数
    
    Float32 *inSide = sndbuf[inBusNumber].data;             //数据
    
    if (inSide) {
    
        Float32 *outL = (Float32 *)ioData->mBuffers[0].mData; // 左声道数据
        Float32 *outR = (Float32 *)ioData->mBuffers[1].mData; // 右声道数据
        
        //数据修改
        for (UInt32 i = 0; i < inNumberFrames; ++i) {
            if (1 == inBusNumber) {
                outL[i] = 0;
                outR[i] = inSide[sample];
                ++sample;
            } else {
                outL[i] = inSide[sample];
                outR[i] = 0;
                ++sample;
            }
        }
    }
    
    //循环效果
    if (sample > bufSamples) {
        sample = 0;
    }
    sndbuf[inBusNumber].sampleNum = sample;//更新样本位置
    
    return noErr;
}


- (BOOL)graphIsRunning {
    Boolean isRunning = false;
    CheckError(AUGraphIsRunning(graph, &isRunning), "AUGraphIsRunning");
    return isRunning;
}

- (BOOL)isPlaying {
    return  [self graphIsRunning];
}

#pragma mark - action
- (void)play {
    [self graphStart];
}

- (void)stop {
    [self graphStop];
}

- (void)replay {
    soundBuffer[0].sampleNum = 0;
    soundBuffer[1].sampleNum = 0;
    [self graphStart];
}

//启动
- (void)graphStart {//开始pull head node -> sub node -> sub node
    if (![self graphIsRunning]) {
        if (CheckError(AUGraphStart(graph), "AUGraphStart") == noErr) {
        }
    }
}

//停止
- (void)graphStop {
    if ([self graphIsRunning]) {
        if (CheckError(AUGraphStop(graph), "AUGraphStop") == noErr) {
        
        }//stop pull
    }
}

//控制mixerUnit某个input bus是否可用配置
- (void)enableBusInput:(UInt32)busInputNumber isOn:(AudioUnitParameterValue)isOn {
    CheckError(AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, busInputNumber, isOn, 0), "kMultiChannelMixerParam_Enable");
}

//控制mixerUnit input bus的音量
- (void)setBusInput:(UInt32)busInputNumber volume:(AudioUnitParameterValue)volume {
    CheckError(AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, busInputNumber, volume, 0), "kMultiChannelMixerParam_Volume");
}

//控制mixerUnit output bus的音量
- (void)setOutputBusVolume:(AudioUnitParameterValue)volume {
    CheckError(AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, volume, 0), "kMultiChannelMixerParam_Volume");
}




@end
