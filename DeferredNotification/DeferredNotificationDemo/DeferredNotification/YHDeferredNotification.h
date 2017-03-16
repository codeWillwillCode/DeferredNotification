//
//  YHDeferredNotification.h
//  DeferredNotification
//
//  Created by ye on 17/3/14.
//  Copyright © 2017年 ye. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, YHDeferredOptions) {
    YHDeferredOptionsAfter   = 0,        // 默认
    YHDeferredOptionsBefore  = 2,
    YHDeferredOptionsOnece   = 1 << 3
};

typedef void (^YHHandler)(id data);

@interface NSObject (YHDeferredNotification)

- (void)subscribe:(NSString *)eventName onSelector:(SEL)selector withOptions:(YHDeferredOptions)option handler:(YHHandler)handler;

- (void)publish:(NSString *)name;

- (void)publish:(NSString *)name data:(id)data;

- (void)unsubscribe:(NSString *)eventName;

- (void)unsubscribe:(NSString *)name selector:(SEL)selector;

- (void)unsubscribeAll;

@end
