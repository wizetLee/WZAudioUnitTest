//
//  ViewController.m
//  WZAudioUnitTest
//
//  Created by admin on 4/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "ViewController.h"

#import "WZPlayPCMController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIORenderCallController.h"
#import "WZMIDIController.h"
#import "WZAVCaptureToAudioUnitController.h"
#import "WZAudioFile.h"
#import "WZExtendedAudioFile.h"
#import "WZMultichannelMixerController.h"
#import "WZMatrixMixerController.h"

#define CELLID @"UITableViewCell"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray <WZCatalogueModel *>*data;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = false;
  
    _data = NSMutableArray.array;
    
    [self addWithClass:WZPlayPCMController.class];
    [self addWithClass:WZIOPassThroughViewController.class];
    [self addWithClass:WZIORenderCallController.class];
    [self addWithClass:WZMIDIController.class];
    [self addWithClass:WZAVCaptureToAudioUnitController.class];
    [self addWithClass:WZAudioFile.class];
    [self addWithClass:WZExtendedAudioFile.class];
    [self addWithClass:WZMultichannelMixerController.class];
    [self addWithClass:WZMatrixMixerController.class];
    
}

- (void)addWithClass:(Class)class {
    [self addWithClass:class headline:nil fromXIB:true];
}

- (void)addWithClass:(Class)class headline:(NSString *)headline fromXIB:(BOOL)fromXIB {
    WZCatalogueModel *model = WZCatalogueModel.new;
    model.fromXIB = fromXIB;
    model.headline = headline;
    model.aClass = class.class;
    [_data addObject:model];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if(!_table) {
        UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.view addSubview:table];
        if (@available(iOS 11.0, *)) {
            table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        table.delegate = self;
        table.dataSource = self;
        table.backgroundColor = UIColor.whiteColor;
        table.estimatedRowHeight = UITableViewAutomaticDimension;
        table.estimatedSectionFooterHeight = 0.0;
        table.estimatedSectionHeaderHeight = 0.0;
        
        [table registerClass:[UITableViewCell class] forCellReuseIdentifier:CELLID];
        
        CGFloat top = 64.0;
        CGFloat bottom = 0.0;
        CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
        CGFloat screenH = UIScreen.mainScreen.bounds.size.height;
        
        if (@available(iOS 11, *)) {
            top = self.view.safeAreaInsets.top;
            bottom = self.view.safeAreaInsets.bottom;
        }
        
        CGFloat height = screenH - bottom - top;
        _table = table;
        self.table.frame = CGRectMake(0.0, top, screenW, height);
    }
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= _data.count) {return;}
    
    WZCatalogueModel *model = _data[indexPath.row];
    UIViewController *VC = [[model.aClass alloc] initWithNibName:NSStringFromClass(model.aClass) bundle:NSBundle.mainBundle];
    [self.navigationController pushViewController:VC animated:true];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELLID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELLID];
    }
    if (indexPath.row >= _data.count) {return cell;}
    
    WZCatalogueModel *model = _data[indexPath.row];
    if (!model.headline) {
        cell.textLabel.text = NSStringFromClass(model.aClass);
    }
    return cell;
}

@end

#pragma mark - 模型
@interface WZCatalogueModel()



@end

@implementation WZCatalogueModel

@end
