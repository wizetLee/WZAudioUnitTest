//
//  ViewController.h
//  WZAudioUnitTest
//
//  Created by admin on 4/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController


@end

@interface WZCatalogueModel : NSObject

@property (nonatomic, strong) Class aClass;
@property (nonatomic, strong) NSString *headline;
@property (nonatomic, assign) BOOL fromXIB;

@end
