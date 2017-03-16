//
//  BViewController.m
//  DeferredNotification
//
//  Created by ye on 17/3/16.
//  Copyright © 2017年 ye. All rights reserved.
//

#import "BViewController.h"
#import "YHDeferredNotification.h"

@interface BViewController ()

@end

@implementation BViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"发送刷新信号" forState:UIControlStateNormal];
    [button sizeToFit];
    button.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame)-CGRectGetHeight(button.frame));
    [self.view addSubview:button];
    
    UIButton *buttonP = [UIButton buttonWithType:UIButtonTypeSystem];
    [buttonP addTarget:self action:@selector(refreshByPostData:) forControlEvents:UIControlEventTouchUpInside];
    [buttonP setTitle:@"发送刷新数据" forState:UIControlStateNormal];
    [buttonP sizeToFit];
    buttonP.frame = CGRectOffset(button.frame, 0, CGRectGetHeight(button.frame));
    [self.view addSubview:buttonP];
    
}

- (void)refresh:(UIButton *)button{
    [self publish:@"NotificationB"];
}

- (void)refreshByPostData:(UIButton *)button{
    [self publish:@"NotificationB" data:@"haha"];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
