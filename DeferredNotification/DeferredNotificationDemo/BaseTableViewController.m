//
//  BaseTableViewController.m
//
//  Created by ye on 17/3/2.
//  Copyright © 2017年 ye. All rights reserved.
//

#import "BaseTableViewController.h"
#import "AViewController.h"
#import "YHDeferredNotification.h"
@interface BaseTableViewController ()

@property (nonatomic,strong) NSArray *modelArray;

@end

@implementation BaseTableViewController
@synthesize refreshControl = _refreshControl;

- (void)dealloc{
    [self unsubscribeAll];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.tableHeaderView = self.refreshControl;
    self.modelArray = @[@{
                            @"title": @"从其他页面传值回来",
                            @"instanceClass": [AViewController class]
                            },
                        @{
                            @"title": @"一次性订阅",
                            @"instanceClass": [AViewController class]
                            }
                        ];
    
    [self subscribe];
}

#pragma mark - event -

- (void)startRefresh:(id)sender{
    NSLog(@"start refresh");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}


- (void)subscribe{
    __weak __typeof__(self) weakSelf = self;
    
    [self subscribe:@"NotificationA" onSelector:@selector(viewWillAppear:) withOptions:YHDeferredOptionsAfter|YHDeferredOptionsOnece handler:^(id data){
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        NSLog(@"receive NotificationA!");
        if (data) {
            NSLog(@"data:%@",data);
        }
        [strongSelf.refreshControl beginRefreshing];
        [strongSelf.tableView setContentOffset:CGPointMake(0, strongSelf.tableView.contentOffset.y-strongSelf.refreshControl.frame.size.height) animated:YES];
        [strongSelf.refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
    }];
}

#pragma mark - tableView delegate -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.modelArray.count;
}

static NSString *cellIdentifier = @"cellIdentifier";
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = self.modelArray[indexPath.row][@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Class class = self.modelArray[indexPath.row][@"instanceClass"];
    UIViewController *nextVC = [class new];
    [self.navigationController pushViewController:nextVC animated:YES];
}

#pragma mark - getter&setter -

- (UIRefreshControl *)refreshControl{
    if (_refreshControl) {
        return _refreshControl;
    }
    _refreshControl = [UIRefreshControl new];
    [_refreshControl addTarget:self action:@selector(startRefresh:) forControlEvents:UIControlEventValueChanged];
    return _refreshControl;
}

- (void)setRefreshControl:(UIRefreshControl *)refreshControl{
    [super setRefreshControl:refreshControl];
}

@end
