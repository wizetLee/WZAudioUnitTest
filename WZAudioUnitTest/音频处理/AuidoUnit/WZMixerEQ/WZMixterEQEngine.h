//
//  WZMixterEQEngine.h
//  WZAudioUnitTest
//
//  Created by admin on 8/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
   mixer 0> iPod EQ -> output
 */
@interface WZMixterEQEngine : NSObject

- (void)stop;
- (void)start;

@end
