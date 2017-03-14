//
//  YHDeferredNotification.m
//  DeferredNotification
//
//  Created by ye on 17/3/14.
//  Copyright © 2017年 ye. All rights reserved.
//

#import "YHDeferredNotification.h"
#import "Aspects.h"

@interface YHDeferredManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic,strong) NSMutableDictionary *observers;
@property (nonatomic,strong) NSMutableDictionary *subscriptions;

@end

@interface YHDeferredInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id block;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) YHDeferredOptions option;
@property (nonatomic, strong) id<AspectToken> token;

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
        _observers = [NSMutableDictionary new];
        _subscriptions = [NSMutableDictionary new];
        
    }
    return self;
}

static NSString *subscriptionKey(Class class){
    return [NSString stringWithFormat:@"deferredNotification_%@",NSStringFromClass([class class])];
}

- (id<AspectToken>)hookInstance:(id)instance selector:(SEL)selector option:(YHDeferredOptions)option{
    __weak __typeof__(self) weakSelf = self;
    AspectOptions aspOption = option & ~YHDeferredOptionsOnece;
    
    return [instance aspect_hookSelector:selector withOptions:aspOption
                              usingBlock:^(id<AspectInfo>info){
                                  __strong __typeof__(weakSelf) strongSelf = weakSelf;
                                  if (!instance) return;
                                  
                                  NSMutableSet *infosArray = [strongSelf.subscriptions objectForKey:subscriptionKey(instance)];
                                  [infosArray enumerateObjectsUsingBlock:^(YHDeferredInfo *info, BOOL * _Nonnull stop) {
                                      YHHandler block = info.block;
                                      if (option & YHDeferredOptionsOnece) {
                                          [info.token remove];
                                      }
                                      block(info.data);
                                  }];
                                  [strongSelf.subscriptions removeObjectForKey:subscriptionKey(instance)];
                                  
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
        YHDeferredInfo *info = [YHDeferredInfo new];
        info.name = eventName;
        info.block = handler;
        info.selector = selector;
        info.option = option;
        info.token = token;
        info.data = [note.userInfo objectForKey:kYHDeferredNotificationKey];
        
        NSMutableSet *infosSet = [strongSelf.subscriptions objectForKey:eventName];
        if (!infosSet) {
            infosSet = [NSMutableSet set];
        }
        [infosSet addObject:info];
        [strongSelf.subscriptions setObject:infosSet forKey:subscriptionKey(instance)];
    }];
    
    NSMutableSet *observersSet = [self.observers objectForKey:subscriptionKey(instance)];
    if (!observersSet) {
        observersSet = [NSMutableSet set];
    }
    [observersSet addObject:observer];
    [self.observers setObject:observersSet forKey:subscriptionKey(instance)];
    
}

- (void)instance:(__unsafe_unretained id)instance publish:(NSString *)eventName{
    [self instance:self publish:eventName data:nil];
}

- (void)instance:(__unsafe_unretained id)instance publish:(NSString *)eventName data:(id)data{
    NSCParameterAssert(instance);
    NSCParameterAssert(eventName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:eventName object:self userInfo:!data?nil:@{kYHDeferredNotificationKey: data}];
}

- (void)instance:(__unsafe_unretained id)instance unsubscribe:(NSString *)eventName{
    NSCParameterAssert(instance);
    NSCParameterAssert(eventName);
    
    NSMutableSet *observersSet = [self.observers objectForKey:subscriptionKey(instance)];
    if (!observersSet) {
        return;
    }
    
    NSMutableSet *removeSet = [NSMutableSet set];
    NSEnumerator *enumerator = [observersSet objectEnumerator];
    id value = nil;
    while (value = [enumerator nextObject]) {
        NSString *name = [value valueForKey:@"name"];
        if ([name isEqualToString:eventName]) {
            [removeSet addObject:value];
            [[NSNotificationCenter defaultCenter] removeObserver:value name:name object:self];
        }
    }
    [observersSet minusSet:removeSet];
}

- (void)instanceUnsubscribeAll:(__unsafe_unretained id)instance{
    NSCParameterAssert(instance);
    
    NSMutableSet *observersSet = [self.observers objectForKey:subscriptionKey(instance)];
    if (!observersSet) {
        return;
    }
    
    NSEnumerator *enumerator = [observersSet objectEnumerator];
    id value = nil;
    while (value = [enumerator nextObject]) {
        NSString *name = [value valueForKey:@"name"];
        [[NSNotificationCenter defaultCenter] removeObserver:value name:name object:self];
    }
    [self.observers removeObjectForKey:subscriptionKey(instance)];
}


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

- (void)unsubscribe:(NSString *)eventName{
    [[YHDeferredManager sharedManager] instance:self unsubscribe:eventName];
}

- (void)unsubscribeAll{
    [[YHDeferredManager sharedManager] instanceUnsubscribeAll:self];
}

@end

@implementation YHDeferredInfo

@end
