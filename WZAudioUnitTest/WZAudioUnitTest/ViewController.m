//
//  ViewController.m
//  WZAudioUnitTest
//
//  Created by admin on 4/1/18.
//  Copyright © 2018年 wizet. All rights reserved.
//

#import "ViewController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIORenderCallController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIOPassThroughViewController.h"
#import "WZIOPassThroughViewController.h"

#define CELLID @"UITableViewCell"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray <WZCatalogueModel *>*data;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _data = NSMutableArray.array;
    
    [self addWithClass:WZIOPassThroughViewController.class];
    
    [self addWithClass:WZIORenderCallController.class];
    
    [self addWithClass:WZIORenderCallController.class];
    
    
}

- (void)addWithClass:(Class)class {
    [self addWithClass:class headline:nil fromXIB:true];
}

- (void)addWithClass:(Class)class headline:(NSString *)headline fromXIB:(BOOL)fromXIB {
    WZCatalogueModel *model = WZCatalogueModel.new;
    model.fromXIB = fromXIB;
    model.headline = headline;
    model.aClass = WZIORenderCallController.class;
    [_data addObject:model];
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if(!_table) {
        UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        [self.view addSubview:table];
        
        table.delegate = self;
        table.dataSource = self;
        table.backgroundColor = UIColor.yellowColor;
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
