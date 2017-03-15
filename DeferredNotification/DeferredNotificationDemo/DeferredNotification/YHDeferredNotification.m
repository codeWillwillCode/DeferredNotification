//
//  YHDeferredNotification.m
//  DeferredNotification
//
//  Created by ye on 17/3/14.
//  Copyright © 2017年 ye. All rights reserved.
//

#import "YHDeferredNotification.h"
#import "Aspects.h"
#import <objc/runtime.h>
@interface YHDeferredManager : NSObject

+ (instancetype)sharedManager;

//@property (nonatomic,strong) NSMutableDictionary *observers;
//@property (nonatomic,strong) NSMutableDictionary *subscriptions;
//
@end

@interface YHDeferredInfo : NSObject

@property (nonatomic, weak) id observer;
//@property (nonatomic, strong) id reveiver;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id block;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) SEL selector; 
@property (nonatomic, assign) YHDeferredOptions option;
@property (nonatomic, strong) id<AspectToken> token;
@property (nonatomic, assign) BOOL valid;

@end


@implementation YHDeferredManager


static NSString *const kYHDeferredNotificationKey = @"kYHDeferredNotificationKey";

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
//        _observers = [NSMutableDictionary new];
//        _subscriptions = [NSMutableDictionary new];
        
    }
    return self;
}


- (id<AspectToken>)hookInstance:(id)instance selector:(SEL)selector option:(YHDeferredOptions)option{
    __weak __typeof__(self) weakSelf = self;
    AspectOptions aspOption = option & ~YHDeferredOptionsOnece;
    
    return [instance aspect_hookSelector:selector withOptions:aspOption
                              usingBlock:^(id<AspectInfo>info){
                                  __strong __typeof__(weakSelf) strongSelf = weakSelf;
                                  if (!instance) return;
                                  
                                  NSMutableArray *infosArray = objc_getAssociatedObject(strongSelf, selector);
                                  __block NSArray *infoToRemove = nil;
                                  [infosArray enumerateObjectsUsingBlock:^(YHDeferredInfo *info, NSUInteger idx, BOOL * _Nonnull stop) {
                                      if (!info.valid) {
                                          return;
                                      }
                                      YHHandler block = info.block;
                                      info.valid = NO;
                                      block(info.data);
                                      
                                      if (option & YHDeferredOptionsOnece) {
                                          [info.token remove];
                                          [[NSNotificationCenter defaultCenter] removeObserver:info.observer];
                                          info.token = nil;
                                          info.block = nil;
                                          info.data = nil;
                                          infoToRemove = [infoToRemove?:@[] arrayByAddingObject:info];
                                      }
                                      
                                  }];
                                  if (infoToRemove) {
                                      [infosArray removeObjectsInArray:infoToRemove];
                                  }
                                  
                              }error:NULL];
}

- (void)instance:(__unsafe_unretained id)instance subscribe:(NSString *)eventName handler:(YHHandler)handler onSelector:(SEL)selector withOptions:(YHDeferredOptions)option{
    
    NSCParameterAssert(instance);
    NSCParameterAssert(eventName);
    NSCParameterAssert(selector);
    
    __weak __typeof__(self) weakSelf = self;
    
    id<AspectToken>token = [self hookInstance:instance selector:selector option:option];
    
    id observer =
    [[NSNotificationCenter defaultCenter] addObserverForName:eventName object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        NSArray *infoArray = objc_getAssociatedObject(strongSelf, selector);
        for (YHDeferredInfo *info in infoArray) {
            if (info.name != note.name) {
                continue;
            }
            info.valid = YES;
            info.data = [note.userInfo objectForKey:kYHDeferredNotificationKey];
        }
    }];
    
    YHDeferredInfo *info = [YHDeferredInfo new];
    info.name = eventName;
    info.block = handler;
    info.selector = selector;
    info.option = option;
    info.token = token;
    info.observer = observer;
//    info.reveiver = instance;
    info.valid = NO;
    
    NSMutableArray *infoArray = objc_getAssociatedObject(self, selector);
    if (!infoArray) {
        infoArray = [NSMutableArray new];
        objc_setAssociatedObject(self, selector, infoArray, OBJC_ASSOCIATION_RETAIN);
    }
    [infoArray addObject:info];
}

- (void)instance:(__unsafe_unretained id)instance publish:(NSString *)eventName{
    [self instance:self publish:eventName data:nil];
}

- (void)instance:(__unsafe_unretained id)instance publish:(NSString *)eventName data:(id)data{
    NSCParameterAssert(instance);
    NSCParameterAssert(eventName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:eventName object:self userInfo:!data?nil:@{kYHDeferredNotificationKey: data}];
}

//- (void)instance:(__unsafe_unretained id)instance unsubscribe:(NSString *)eventName{
//    NSCParameterAssert(instance);
//    NSCParameterAssert(eventName);
//    
//    NSMutableSet *observersSet = [self.observers objectForKey:subscriptionKey(instance)];
//    if (!observersSet) {
//        return;
//    }
//    
//    NSMutableSet *removeSet = [NSMutableSet set];
//    NSEnumerator *enumerator = [observersSet objectEnumerator];
//    id value = nil;
//    while (value = [enumerator nextObject]) {
//        NSString *name = [value valueForKey:@"name"];
//        if ([name isEqualToString:eventName]) {
//            [removeSet addObject:value];
//            [[NSNotificationCenter defaultCenter] removeObserver:value name:name object:self];
//        }
//    }
//    [observersSet minusSet:removeSet];
//}
//
//- (void)instanceUnsubscribeAll:(__unsafe_unretained id)instance{
//    NSCParameterAssert(instance);
//    
//    NSMutableSet *observersSet = [self.observers objectForKey:subscriptionKey(instance)];
//    if (!observersSet) {
//        return;
//    }
//    
//    NSEnumerator *enumerator = [observersSet objectEnumerator];
//    id value = nil;
//    while (value = [enumerator nextObject]) {
//        NSString *name = [value valueForKey:@"name"];
//        [[NSNotificationCenter defaultCenter] removeObserver:value name:name object:self];
//    }
//    [self.observers removeObjectForKey:subscriptionKey(instance)];
//}


@end

@implementation NSObject (YHDeferredNotification)

- (void)subscribe:(NSString *)eventName onSelector:(SEL)selector withOptions:(YHDeferredOptions)option handler:(YHHandler)handler{
    [[YHDeferredManager sharedManager] instance:self subscribe:eventName handler:handler onSelector:selector withOptions:option];
}

- (void)publish:(NSString *)name{
    [[YHDeferredManager sharedManager] instance:self publish:name];
}

- (void)publish:(NSString *)name data:(id)data{
    [[YHDeferredManager sharedManager] instance:self publish:name data:data];
}

//- (void)unsubscribe:(NSString *)eventName{
//    [[YHDeferredManager sharedManager] instance:self unsubscribe:eventName];
//}
//
//- (void)unsubscribeAll{
//    [[YHDeferredManager sharedManager] instanceUnsubscribeAll:self];
//}

@end

@implementation YHDeferredInfo

@end
