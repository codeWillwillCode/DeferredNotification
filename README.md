# DeferredNotification

### 前言

大家在开发中都遇到过这样的场景,A界面进入到B界面后(B被A界面pop、modal,甚至是多级pop),在B界面进行了一些操作返回对A界面进行刷新操作.

例如:

- 订单详情进入付款界面后支付完成后返回对订单状态进行刷新.
- 对个人信息进行设置或者编辑,对硬件设备进行配置时,点击若干个"下一步",最后点击完成时回退若干个界面进行刷新.
- 更复杂的跨界面刷新请求

这些都是开发中非常常见的需求,用通俗的开发术语来讲,就是VC间的`逆向传值`.实现`逆向传值`的方式有很多种,通常使用`delegate`,`block`,`通知`等方式.

但是开发中,更多的时候B界面所产生的行为,并不会立即作用在A界面的变化上,而是需要在A界面显示的时候,进行网络请求或者界面更新,增强与用户交互的效果.通常我们会设置一个实例变量标识是否应该刷新,在`viewWillAppear`中对该值进行判断,根据判断结果,再进行网络请求,或者界面的更新.不管对于任何方式的传值而言,这样的处理都是必不可少的.

在实际开发的APP中,特别是电商一类的应用,状态的流转刷新非常的多,为了减少`delegate`和`block`方式下繁琐的相似代码的编写,`通知`在这种情况下成为更好的选择.而在对`通知`的接口进行了一层抽象之后,将会使得项目的接口更加简洁统一.同时,有了`AOP`之后,我们还能移除用来标识是否刷新的实例变量,和执行方法的方法名编写,简直是懒人之福啊🙈.最终我们希望调用接口的时候是这样的:

```objective-c
A界面下注册通知和设置回调:
[self subscribe:@"NotificationA" onSelector:@selector(viewWillAppear:) 		     
    withOptions:YHDeferredOptionsAfter handler:^(id data){
      // 接受到NotificationA ,并且在viewWillAppear:之后,会调用这个handler
      // 最后别忘了在dealloc中移除观察者
 }];


B界面下发出通知:
[self publish:@"NotificationA" data:object];
```

**本文实现的工具**`YHDeferredNotification`**,其原理是在`NSNotificationCenter`与`发布者/订阅者`之间增加一个中间者,对接受到的通知进行"缓存",然后利用`AOP`,拦截`订阅者`特定的方法(例如`viewcontroller`的`viewWillAppear`方法),在该方法前后对"缓存''的通知内容进行调用,达到将通知的内容延迟到特定时机执行的效果.**


![](http://upload-images.jianshu.io/upload_images/651640-ff9cb52cb5356bf6.gif?imageMogr2/auto-orient/strip)
### 利用AOP拦截方法

`AOP`全称`Aspect Oriented Programming`,即`面向切面编程`,平常我们经常使用的`method swizzling`,就是`AOP`的一种实践.之所以选择`Aspects`作为实现`AOP`的框架,是因为该框架的实现相对优雅,API设计也十分简洁精炼.`AOP`虽然功能非常强大并且实用,但是也会降低项目的健壮性.而`Aspects`将这种弊端降到了最低,它通过动态新增一个类来将额外的业务逻辑通过关联对象的形式绑定在新增类身上,其思路与苹果原生的`KVO`类似,这样做的好处就是避开新增的业务逻辑对原生类的"污染".这也是`Aspects`比大部分`method swizzling`实践更为优秀的地方.关于`Aspect`的源码解析[这篇文章](http://wereadteam.github.io/2016/06/30/Aspects/)写的比较好.

### 开源库参考

```objective-c
- (void)subscribe:(NSString *)eventName onSelector:(SEL)selector withOptions:(YHDeferredOptions)option handler:(YHHandler)handler;
- (void)publish:(NSString *)name;
- (void)publish:(NSString *)name data:(id)data;
- (void)unsubscribe:(NSString *)eventName;
- (void)unsubscribe:(NSString *)name selector:(SEL)selector;
- (void)unsubscribeAll;
```

我参考了一款名为[**GLPubSub**](https://github.com/Glow-Inc/GLPubSub#glpubsub-chinese)的开源库,借鉴了它对接口的命名,对`NSNotificationCenter`进行了一层封装.与之不同的地方在于,我在`观察者`和`通知中心`之间增加了一个中间类,将通知信息`缓存`在该类身上,而不是绑定在观察者本身.

## Aspects存在的问题

谈到iOS的`AOP`实现,`Aspects`一直是许多人的首选框架,很多朋友用它来剥离埋点代码,或在一些原生基类中做一些全局性的布置.可以说`Aspects`正如它的描述(`A delightful, simple library.`)一般,让我们完成在原有的框架体系下难以完成的一些简单的业务.

但我在构建这个工具的时候,因为`Aspects`本身的bug遇到了不少的问题.首先`Aspects`的作者已经将近两年没有更新了,在项目的[github页面](https://github.com/steipete/Aspects),我们可以看到有一堆的`pr`和`issues`.其中[#91](https://github.com/steipete/Aspects/issues/91)所提到的问题便是工具中遇到的问题,另外还有一个bug是通过我自己添加代码解决的.所以说`demo`中的`Aspects`并不是原生的`Aspects`.

虽然`Aspects`存在这样那样的问题,并且作者似乎已经"弃坑"了,但对于一般的简单需求例如剥离埋点,在基类做一些简单`method swizzling`而言,这些bug并不会困扰到你.



更多细节,[请看demo](),欢迎提意见!
