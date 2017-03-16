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
@property (nonatomic,strong) dispatch_queue_t deferredQueue;

@end

@interface YHDeferredObserver : NSObject

- (void)remove;

@property (nonatomic, unsafe_unretained) id receiver;
@property (nonatomic, weak) id observer;
@property (nonatomic, copy) id block;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) SEL selector; 
@property (nonatomic, assign) YHDeferredOptions option;
@property (nonatomic, strong) id<AspectToken> token;
@property (nonatomic, assign) BOOL valid;

@end


@implementation YHDeferredManager

static NSString *const kYHDeferredNotificationKey = @"kYHDeferredNotificationKey";

static NSMutableArray *arrayForObservers(YHDeferredManager *self, NSString *key) {
    __block NSMutableArray *ret = nil;
    ret = [self.observers objectForKey:key];
    if (ret) {
        return ret;
    }
    ret = [NSMutableArray new];
    dispatch_barrier_async(self.deferredQueue, ^{
        [self.observers setObject:ret forKey:key];
    });
    return ret;
}

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
        _deferredQueue = dispatch_queue_create("com.YHDeferredNotification.deferredQueue",
                                               DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (id<AspectToken>)hookInstance:(id)instance eventName:(NSString *)name selector:(SEL)selector option:(YHDeferredOptions)option{
    AspectOptions aspOption = option & ~YHDeferredOptionsOnece;
    
    return [instance aspect_hookSelector:selector withOptions:aspOption
                              usingBlock:^(id<AspectInfo>aspectInfo){
                                  if (!aspectInfo.instance) return;
                                  YHDeferredManager *manager = [YHDeferredManager sharedManager];
                                  NSMutableArray *infosArray = arrayForObservers(manager, name);
                                  [infosArray enumerateObjectsUsingBlock:^(YHDeferredObserver *ob, NSUInteger idx, BOOL * _Nonnull stop) {
                                      if (!ob.valid || ob.receiver != aspectInfo.instance) {
                                          return;
                                      }
                                      YHHandler block = ob.block;
                                      ob.valid = NO;
                                      block(ob.data);
                                      if (option & YHDeferredOptionsOnece) {
                                          [manager instance:aspectInfo.instance unsubscribe:name selector:selector];
                                      }
                                  }];
                              }error:NULL];
}

- (void)instance:(__unsafe_unretained id)instance subscribe:(NSString *)eventName handler:(YHHandler)handler onSelector:(SEL)selector withOptions:(YHDeferredOptions)option{
    
    NSCParameterAssert(instance);
    NSCParameterAssert(eventName);
    NSCParameterAssert(selector);
    
    id<AspectToken>token = [self hookInstance:instance eventName:eventName selector:selector option:option];
    
    id observer =
    [[NSNotificationCenter defaultCenter] addObserverForName:eventName object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        YHDeferredManager *manager = [YHDeferredManager sharedManager];
        NSArray *observersArr = arrayForObservers(manager, note.name);
        
        for (YHDeferredObserver *ob in observersArr) {
            if (ob.selector != selector || ob.receiver != instance) {
                continue;
            }
            ob.valid = YES;
            ob.data = [note.userInfo objectForKey:kYHDeferredNotificationKey];
        }
    }];
    
    YHDeferredObserver *ob = [YHDeferredObserver new];
    ob.block = handler;
    ob.selector = selector;
    ob.option = option;
    ob.token = token;
    ob.observer = observer;
    ob.receiver = instance;
    ob.valid = NO;
    
    dispatch_barrier_async(self.deferredQueue, ^{
        [arrayForObservers(self, eventName) addObject:ob];
    });
}

- (void)instance:(__unsafe_unretained id)instance publish:(NSString *)eventName{
    [self instance:self publish:eventName data:nil];
}

- (void)instance:(__unsafe_unretained id)instance publish:(NSString *)eventName data:(id)data{
    NSCParameterAssert(instance);
    NSCParameterAssert(eventName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:eventName object:self userInfo:!data?nil:@{kYHDeferredNotificationKey: data}];
}

- (void)instance:(__unsafe_unretained id)instance unsubscribe:(NSString *)name selector:(SEL)selector{
    NSCParameterAssert(instance);
    NSCParameterAssert(name);
    
    NSMutableArray *obArray = arrayForObservers(self, name);
    if (!obArray) {
        return;
    }
    NSArray *obToRemove = nil;
    for (YHDeferredObserver *ob in obArray) {
        if (ob.receiver != instance) {
            continue;
        }
        if (selector != NULL && ob.selector != selector) {
            continue;
        }
        [ob remove];
        obToRemove = [obToRemove?:@[] arrayByAddingObject:ob];
    }
    
    dispatch_barrier_async(self.deferredQueue, ^{
        [obArray removeObjectsInArray:obToRemove];
    });
}

- (void)instance:(__unsafe_unretained id)instance unsubscribe:(NSString *)name{
    [self instance:instance unsubscribe:name selector:nil];
}

- (void)instanceUnsubscribeAll:(__unsafe_unretained id)instance{
    NSCParameterAssert(instance);
    NSArray *copiedAllKeys = [[self.observers allKeys] copy];
    for (NSString *curName in copiedAllKeys) {
        [self instance:instance unsubscribe:curName];
    }
}

@end

@implementation NSObject (YHDeferredNotification)

- (void)subscribe:(NSString *)name onSelector:(SEL)selector withOptions:(YHDeferredOptions)option handler:(YHHandler)handler{
    [[YHDeferredManager sharedManager] instance:self subscribe:name handler:handler onSelector:selector withOptions:option];
}

- (void)publish:(NSString *)name{
    [[YHDeferredManager sharedManager] instance:self publish:name];
}

- (void)publish:(NSString *)name data:(id)data{
    [[YHDeferredManager sharedManager] instance:self publish:name data:data];
}

- (void)unsubscribe:(NSString *)name{
    [[YHDeferredManager sharedManager] instance:self unsubscribe:name];
}

- (void)unsubscribe:(NSString *)name selector:(SEL)selector{
    [[YHDeferredManager sharedManager] instance:self unsubscribe:name selector:selector];
}

- (void)unsubscribeAll{
    [[YHDeferredManager sharedManager] instanceUnsubscribeAll:self];
}

@end

@implementation YHDeferredObserver

- (void)remove{
    [self.token remove];
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
    self.observer = nil;
    self.receiver = nil;
    self.token = nil;
    self.block = nil;
    self.data = nil;
}

@end
