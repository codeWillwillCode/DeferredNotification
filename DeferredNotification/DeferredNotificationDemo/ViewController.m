//
//  ViewController.m
//  DeferredNotification
//
//  Created by ye on 17/3/13.
//  Copyright © 2017年 ye. All rights reserved.
//

#import "ViewController.h"
#import "BaseTableViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Main ViewController" forState:UIControlStateNormal];
    [button sizeToFit];
    button.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame)-CGRectGetHeight(button.frame));
    [self.view addSubview:button];

}


- (void)refresh:(UIButton *)button {
    [self.navigationController pushViewController:[BaseTableViewController new] animated:YES];
}


@end
