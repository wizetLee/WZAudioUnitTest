//
//  WZMixterEQEngine.m
//  WZAudioUnitTest
//
//  Created by admin on 8/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "WZMixterEQEngine.h"
#include "CAStreamBasicDescription.h"

#define SAMPLERATE 44100.0

#define MAXBUFS  2
typedef struct {
    AudioStreamBasicDescription asbd;
    SInt16 *data;
    UInt32 numFrames;
} SoundBuffer, *SoundBufferPtr;

typedef struct {
    UInt32 frameNum;
    UInt32 maxNumFrames;
    SoundBuffer soundBuffer[MAXBUFS];
} SourceAudioBufferData, *SourceAudioBufferDataPtr;


@interface WZMixterEQEngine()
{
    AUGraph graph;
    AudioUnit mixerUnit;
    AudioUnit EQUnit;
    AudioUnit outputUnit;
    
    CAStreamBasicDescription clientFormat;
    CAStreamBasicDescription outputFormat;
    
    SourceAudioBufferData userData;
    
}
@end

@implementation WZMixterEQEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        memset(&userData.soundBuffer, 0, sizeof(userData.soundBuffer));
        ///配属性
        clientFormat.SetCanonical(2, true);//立体
        clientFormat.mSampleRate = SAMPLERATE;
//        clientFormat.Print();
        
        outputFormat.SetAUCanonical(2, false);//输出时单声道：但是官方说明   单声道channel为1啊~~~
        outputFormat.mSampleRate = SAMPLERATE;
       
        [self configFiles];
        [self configGraph];
        
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 0, 1, 0);
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 1, 1, 0);
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, 0.5, 0);
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, 0.5, 0);
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, 1, 0);
        
        CheckError(AUGraphStart(graph), "start");
    }
    return self;
}


- (void)stop {
    CheckError(AUGraphStop(graph), "start");
}
- (void)start {
    CheckError(AUGraphStart(graph), "start");
}

- (void)configFiles {
    NSArray <NSString *>*pathArr = @[
                                    [[NSBundle mainBundle] pathForResource:@"祝君好" ofType:@"mp3"],
                                    [[NSBundle mainBundle] pathForResource:@"Secretofmyheart" ofType:@"mp3"]
                                    ];
    userData.frameNum = 0;
    userData.maxNumFrames = 0;
    
        for (int i = 0; i < pathArr.count  && i < MAXBUFS; i++)  {
            ExtAudioFileRef xafref = 0;
            ExtAudioFileOpenURL(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)pathArr[i], kCFURLPOSIXPathStyle, false), &xafref);
            
            CAStreamBasicDescription fileFormat;
            UInt32 propSize = sizeof(fileFormat);
            CheckError(ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat), "fileFormat");
            CheckError(ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, sizeof(clientFormat), &clientFormat), "设置buffer文件格式出错");
            
            SInt64 numFrames = 0;
            propSize = sizeof(numFrames);//frame 存储起来
            ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
            
            if (numFrames > userData.maxNumFrames) userData.maxNumFrames = (UInt32)numFrames;///取最长的那一段
            
            userData.soundBuffer[i].numFrames = (UInt32)numFrames;//总帧数
            userData.soundBuffer[i].asbd = clientFormat;//格式
            //分配缓存
            UInt32 samples = (UInt32)numFrames * userData.soundBuffer[i].asbd.mChannelsPerFrame;
            userData.soundBuffer[i].data = (SInt16 *)calloc(samples, sizeof(SInt16));
            
            AudioBufferList ABL;
            ABL.mNumberBuffers = 1;
            ABL.mBuffers[0].mNumberChannels = userData.soundBuffer[i].asbd.mChannelsPerFrame;
            ABL.mBuffers[0].mData = userData.soundBuffer[i].data;
            ABL.mBuffers[0].mDataByteSize = samples * sizeof(SInt16);
            
            UInt32 numPackets = (UInt32)numFrames;
            if (ExtAudioFileRead(xafref, &numPackets, &ABL)) {
                free(userData.soundBuffer[i].data);
                userData.soundBuffer[i].data = 0;
            }
            ExtAudioFileDispose(xafref);
        }
}

// the render notification is used to keep track of the frame number position in the source audio
static OSStatus renderNotification(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    SourceAudioBufferDataPtr userData = (SourceAudioBufferDataPtr)inRefCon;
    
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        
        //printf("post render notification frameNum %ld inNumberFrames %ld\n", userData->frameNum, inNumberFrames);
        
        userData->frameNum += inNumberFrames;
        if (userData->frameNum >= userData->maxNumFrames) {
            userData->frameNum = 0;
        }
    }
    
    return noErr;
}


OSStatus inputRender (    void *                            inRefCon,
                      AudioUnitRenderActionFlags *    ioActionFlags,
                      const AudioTimeStamp *            inTimeStamp,
                      UInt32                            inBusNumber,
                      UInt32                            inNumberFrames,
                      AudioBufferList * __nullable    ioData) {
    
    SourceAudioBufferDataPtr userData = (SourceAudioBufferDataPtr)inRefCon;
    
    SInt16 *in = userData->soundBuffer[inBusNumber].data;
    SInt16 *out = (SInt16 *)ioData->mBuffers[0].mData;
    
    UInt32 sample = userData->frameNum * userData->soundBuffer[inBusNumber].asbd.mChannelsPerFrame;
    ///帧数 * 通道数 = buffer大小
    
    // make sure we don't attempt to render more data than we have available in the source buffers
    // if one buffer is larger than the other, just render silence for that bus until we loop around again
    if ((userData->frameNum + inNumberFrames) > userData->soundBuffer[inBusNumber].numFrames) {
        UInt32 offset = (userData->frameNum + inNumberFrames) - userData->soundBuffer[inBusNumber].numFrames;
        //两个文件都要经过这里，计算出是否溢出，如果是则静默状态，不是就继续拷贝剩余部分的数据
        if (offset < inNumberFrames) {//拷贝剩余部分的数据
            // copy the last bit of source
            SilenceData(ioData);
            ///数据拷贝
            memcpy(out, &in[sample], ((inNumberFrames - offset) * userData->soundBuffer[inBusNumber].asbd.mBytesPerFrame));
            return noErr;
        } else {
            // we have no source data
            SilenceData(ioData);
            *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence; ///静默配置
            return noErr;
        }
    }
    
    memcpy(out, &in[sample], ioData->mBuffers[0].mDataByteSize);
    
    //printf("render input bus %ld from sample %ld\n", inBusNumber, sample);
    return noErr;
}

// render some silence
static void SilenceData(AudioBufferList *inData)
{
    for (UInt32 i=0; i < inData->mNumberBuffers; i++)
        memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}


- (void)configGraph {
    
    CheckError(NewAUGraph(&graph), __func__);
    
    AUNode eqNode, mixerNode, outputNode;
    
    AudioComponentDescription ACD = {};
    ACD.componentFlags = 0;
    ACD.componentFlagsMask = 0;
    ACD.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    ACD.componentType = kAudioUnitType_Output;
    ACD.componentSubType = kAudioUnitSubType_RemoteIO;
    CheckError(AUGraphAddNode(graph, &ACD, &outputNode), "addNode");
    
    ACD.componentType = kAudioUnitType_Mixer;
    ACD.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    CheckError(AUGraphAddNode(graph, &ACD, &mixerNode), "addNode");
    
    ACD.componentType = kAudioUnitType_Effect;
    ACD.componentSubType = kAudioUnitSubType_AUiPodEQ;
    CheckError(AUGraphAddNode(graph, &ACD, &eqNode), "addNode");
    
    ///铺流水
    AUGraphConnectNodeInput(graph, mixerNode, 0, eqNode, 0);
    AUGraphConnectNodeInput(graph, eqNode, 0, outputNode, 0);
    
    CheckError(AUGraphOpen(graph), "open");
    
    AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit);
    AUGraphNodeInfo(graph, mixerNode, NULL, &mixerUnit);
    AUGraphNodeInfo(graph, eqNode, NULL, &EQUnit);
    
   
    UInt32 numbuses = 2;
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, sizeof(UInt32)), "count");
    
    for (UInt32 i = 0; i < numbuses; i++) {
        AURenderCallbackStruct RCS = {};
        RCS.inputProc = &inputRender;
        RCS.inputProcRefCon = &userData;
        
        AUGraphSetNodeInputCallback(graph, mixerNode, i, &RCS);
        
        CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &clientFormat, sizeof(clientFormat)), "format");
    }
    
#pragma mark - 读取preset列表
    CFArrayRef presetList;
    UInt32 size = sizeof(presetList);
    CheckError(AudioUnitGetProperty(EQUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &presetList, &size), "list");
    
    //打印
    //    UInt8 count = CFArrayGetCount(presetList);
    //    for (int i = 0; i < count; ++i) {
    //        AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(presetList, i);
    //        CFShow(aPreset->presetName);
    //    }
    
    AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &outputFormat, sizeof(outputFormat));
    AudioUnitSetProperty(EQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &outputFormat, sizeof(outputFormat));
    
    //注册一个在render之前的回调  用于匹配帧位置
    AUGraphAddRenderNotify(graph, renderNotification, &userData);//在render call之后调用后此;
    
    CheckError(AUGraphInitialize(graph), "initialize");
    CAShow(graph);
}


@end
