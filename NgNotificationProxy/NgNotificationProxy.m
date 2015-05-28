//
//  NgNotificationProxy.m
//  Meiwin
//
//  Created by Meiwin Fu on 12/3/15.
//  Copyright (c) 2015 meiwin. All rights reserved.
//

#import "NgNotificationProxy.h"
#import "NgWeakProxy.h"
#import "NgWeakProxySubclass.h"

#define NgNotificationProxyThreadUserDefined 0xff

#pragma mark -
@class NgNotificationProxySubscriber;
@protocol NgNotificationProxySubscriberDelegate
@optional
- (void)subscriberDidReceiveNotificationButNotInTargetThread:(NgNotificationProxySubscriber *)subscriber;
- (void)subscriberDidBecomeInvalid:(NgNotificationProxySubscriber *)subscriber;
@end

@interface NgNotificationProxySubscriber : NgWeakProxy
{
  __weak id _object;
}
@property (nonatomic, strong, readonly) NSString * identifier;
@property (nonatomic, strong, readonly) NSString * name;
@property (nonatomic, weak) id<NgNotificationProxySubscriberDelegate> delegate;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, strong, readonly) NSThread * targetThread;
@property (nonatomic, weak, readonly) id object;
+ (instancetype)subscriberWithTarget:(id)target
                            selector:(SEL)selector
                        targetThread:(NSThread *)targetThread
                                name:(NSString *)name
                              object:(id)object;
- (void)invoke:(NSNotification *)notification;
- (void)processNotifications;
@end

@interface NgNotificationProxySubscriber () <NgNotificationProxySubscriberDelegate>
{
  struct {
    int didReceiveNotificationButNotInTargetThread;
    int didBecomeInvalid;
  } _delegateFlags;
  
  NSMutableArray * _notifications;
  NSLock * _lock;
  
}
- (void)setSelector:(SEL)selector;
- (void)setTargetThread:(id)targetThread;
@end

@implementation NgNotificationProxySubscriber
+ (instancetype)subscriberWithTarget:(id)target
                            selector:(SEL)selector
                        targetThread:(NSThread *)targetThread
                                name:(NSString *)name
                              object:(id)object
{
  NgNotificationProxySubscriber * subscriber = [[NgNotificationProxySubscriber alloc] init];
  [subscriber setTarget:target];
  subscriber.selector = selector;
  subscriber.targetThread = targetThread;
  subscriber.name = name;
  subscriber.object = object;
  return subscriber;
}
- (id)init
{
  self = [super init];
  if (self)
  {
    _identifier = [[NSUUID UUID] UUIDString];
    _notifications = [NSMutableArray array];
    _lock = [[NSLock alloc] init];
  }
  return self;
}
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)processNotifications
{
  [_lock lock];
  NSArray * notifications = [_notifications copy];
  [_notifications removeAllObjects];
  [_lock unlock];
  
  id safeTarget = self.safeTarget;
  if (safeTarget)
  {
    [notifications enumerateObjectsUsingBlock:^(NSNotification * notification, NSUInteger idx, BOOL *stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [safeTarget performSelector:_selector withObject:notification];
#pragma clang diagnostic pop
    }];
  }
  else
  {
    [self didBecomeInvalid];
  }
}
- (void)invoke:(NSNotification *)notification
{
  if (_targetThread == nil)
  {
    id safeTarget = self.safeTarget;
    if (safeTarget)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [safeTarget performSelector:_selector withObject:notification];
#pragma clang diagnostic pop
    }
    else
    {
      [self didBecomeInvalid];
    }
  }
  else
  {
    [_lock lock];
    [_notifications addObject:notification];
    [_lock unlock];
    
    if ([NSThread currentThread] == _targetThread)
    {
      [self processNotifications];
    }
    else
    {
      [self didReceiveNotificationButNotInTargetThread];
    }
  }
}
#pragma mark Private Methods
- (void)setSelector:(SEL)selector
{
  _selector = selector;
}
- (void)setTargetThread:(id)targetThread
{
  _targetThread = targetThread;
}
- (void)setName:(NSString *)name
{
  _name = name;
}
- (void)setObject:(id)object
{
  _object = object;
}
- (id)object
{
  __strong id obj = _object;
  return obj;
}

#pragma mark Delegate
- (void)setDelegate:(id<NgNotificationProxySubscriberDelegate>)delegate
{
  _delegate = delegate;
  _delegateFlags.didReceiveNotificationButNotInTargetThread = _delegate && [(id)_delegate respondsToSelector:@selector(subscriberDidReceiveNotificationButNotInTargetThread:)];
  _delegateFlags.didBecomeInvalid = _delegate && [(id)_delegate respondsToSelector:@selector(subscriberDidBecomeInvalid:)];
}
- (void)didReceiveNotificationButNotInTargetThread
{
  if (_delegateFlags.didReceiveNotificationButNotInTargetThread) [_delegate subscriberDidReceiveNotificationButNotInTargetThread:self];
}
- (void)didBecomeInvalid
{
  if (_delegateFlags.didBecomeInvalid) [_delegate subscriberDidBecomeInvalid:self];
}

@end

#pragma mark -
@class NgNotificationProxyInternal;
@protocol NgNotificationProxyInternalDelegate
@optional
- (void)internal:(NgNotificationProxyInternal *)internal subscriberDidBecomeInvalid:(NgNotificationProxySubscriber *)proxy;
@end

@interface NgNotificationProxyInternal : NSObject <NSMachPortDelegate>
{
  NSMutableDictionary * _subscribers;
  NSMutableSet * _subscriberIdsWithPendingNotifications;
  struct {
    int subscriberDidBecomeInvalid;
  } _delegateFlags;
}
@property (nonatomic, strong, readonly) NSThread * thread;
@property (nonatomic, strong, readonly) NSMachPort * notificationPort;
@property (nonatomic, strong, readonly) NSLock * notificationLock;
@property (nonatomic, weak) id<NgNotificationProxyInternalDelegate> delegate;
- (instancetype)initWithThreadName:(NSString *)threadName;
- (instancetype)initWithThread:(NSThread *)thread;
@end

@implementation NgNotificationProxyInternal
- (id)initWithThreadName:(NSString *)threadName
{
  self = [super init];
  if (self)
  {
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntryPoint:) object:nil];
    _thread.name = threadName;
    [_thread start];
  }
  return self;
}
- (id)initWithThread:(NSThread *)thread
{
  self = [super init];
  if (self)
  {
    _thread = thread;
    if ([NSThread currentThread] == _thread)
    {
      [self threadEntryPoint:nil];
    }
    else
    {
      [self performSelector:@selector(threadEntryPoint:) onThread:_thread withObject:nil waitUntilDone:NO];
    }
  }
  return self;
}
- (void)threadEntryPoint:(id)__unused object
{
  NSRunLoop * runLoop = [NSRunLoop currentRunLoop];
  _notificationPort = [[NSMachPort alloc] init];
  _notificationPort.delegate = self;
  [runLoop addPort:_notificationPort forMode:NSRunLoopCommonModes];
  _notificationLock = [[NSLock alloc] init];
  _subscribers = [NSMutableDictionary dictionary];
  _subscriberIdsWithPendingNotifications = [NSMutableSet set];
  if (runLoop.currentMode == nil && [NSRunLoop mainRunLoop] != runLoop)
  {
    [runLoop run];
  }
}

#pragma mark Delegate
- (void)setDelegate:(id<NgNotificationProxyInternalDelegate>)delegate
{
  _delegate = delegate;
  _delegateFlags.subscriberDidBecomeInvalid = _delegate && [(id)_delegate respondsToSelector:@selector(internal:subscriberDidBecomeInvalid:)];
}
- (void)proxyDidBecomeInvalid:(NgNotificationProxySubscriber *)subscriber
{
  if (_delegateFlags.subscriberDidBecomeInvalid) [_delegate internal:self subscriberDidBecomeInvalid:subscriber];
}

#pragma mark NSMachPortDelegate
- (void)handleMachMessage:(void *)msg
{
  [_notificationLock lock];
  NSDictionary * subscribers = [_subscribers copy];
  NSSet * subscribersWithPendingNotifications = [_subscriberIdsWithPendingNotifications copy];
  [_subscriberIdsWithPendingNotifications removeAllObjects];
  [_notificationLock unlock];
  
  [subscribersWithPendingNotifications enumerateObjectsUsingBlock:^(NSString * subscriberId, BOOL *stop) {
    NgNotificationProxySubscriber * subscriber = subscribers[subscriberId];
    [subscriber processNotifications];
  }];
}

#pragma mark NgNotificationProxySubscriberDelegate
- (void)subscriberDidBecomeInvalid:(NgNotificationProxySubscriber *)subscriber
{
  [_notificationLock lock];
  [_subscribers removeObjectForKey:subscriber.identifier];
  [_notificationLock unlock];
  [self proxyDidBecomeInvalid:subscriber];
}
- (void)subscriberDidReceiveNotificationButNotInTargetThread:(NgNotificationProxySubscriber *)subscriber
{
  [_notificationLock lock];
  [_subscriberIdsWithPendingNotifications addObject:subscriber.identifier];
  _subscribers[subscriber.identifier] = subscriber;
  [_notificationLock unlock];
  [_notificationPort sendBeforeDate:[NSDate date]
                         components:nil
                               from:nil
                           reserved:0];
}
@end

#pragma mark -
@interface NgNotificationProxyRegistry : NSObject
{
  NSLock * _registryLock;
  NSMutableDictionary * _registries;
}
+ (instancetype)sharedInstance;
- (NgNotificationProxyInternal *)internalNamed:(NSString *)name;
@end

@implementation NgNotificationProxyRegistry
+ (instancetype)sharedInstance
{
  static NgNotificationProxyRegistry * _sharedRegistry;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedRegistry = [[NgNotificationProxyRegistry alloc] init];
  });
  return _sharedRegistry;
}
- (instancetype)init
{
  self = [super init];
  if (self)
  {
    _registryLock = [[NSLock alloc] init];
    _registries = [NSMutableDictionary dictionaryWithCapacity:5];
  }
  return self;
}
- (NgNotificationProxyInternal *)internalNamed:(NSString *)name
{
  NgNotificationProxyInternal * internal = _registries[name];
  if (!internal)
  {
    [_registryLock lock];
    internal = [[NgNotificationProxyInternal alloc] initWithThreadName:name];
    _registries[name] = internal;
    [_registryLock unlock];
  }
  return internal;
}
@end

#pragma mark - Event
@interface NgNotificationProxy () <NgNotificationProxySubscriberDelegate, NgNotificationProxyInternalDelegate>
{
  NSLock * _lock;
  NSMutableArray * _subscribers;
}
@end

@implementation NgNotificationProxy

- (id)init
{
  self = [super init];
  if (self)
  {
    _subscribers = [NSMutableArray arrayWithCapacity:100];
    _lock = [[NSLock alloc] init];
  }
  return self;
}
- (void)dealloc {
  [self removeAllObservers];
}
+ (instancetype)defaultProxy
{
  static NgNotificationProxy * _defaultProxy;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _defaultProxy = [[NgNotificationProxy alloc] init];
  });
  return _defaultProxy;
}

#pragma mark Private
- (NgNotificationProxyInternal *)internalForMainThread
{
  static NgNotificationProxyInternal * _mainInternal;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _mainInternal = [[NgNotificationProxyInternal alloc] initWithThread:[NSThread mainThread]];
    _mainInternal.delegate = self;
  });
  return _mainInternal;
}

#pragma mark Private Methods
- (void)addObserver:(id)target
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object
             thread:(NgNotificationProxyThread)thread
         threadName:(NSString *)threadName
{
  NSThread * threadObject = nil;
  id<NgNotificationProxySubscriberDelegate> proxyDelegate = nil;
  if (thread == NgNotificationProxyThreadCurrent)
  {
    proxyDelegate = self;
    threadObject = nil;
  }
  else if (thread == NgNotificationProxyThreadMain)
  {
    proxyDelegate = (id<NgNotificationProxySubscriberDelegate>)[self internalForMainThread];
    threadObject = [NSThread mainThread];
  }
  else if (thread == NgNotificationProxyThreadBackground)
  {
    NgNotificationProxyInternal * internal = [[NgNotificationProxyRegistry sharedInstance] internalNamed:@"NgNotificationProxy.internal.background"];
    internal.delegate = self;
    proxyDelegate = (id<NgNotificationProxySubscriberDelegate>)internal;
    threadObject = internal.thread;
  }
  else if ((int)thread == NgNotificationProxyThreadUserDefined)
  {
    NgNotificationProxyInternal * internal = [[NgNotificationProxyRegistry sharedInstance] internalNamed:threadName];
    internal.delegate = self;
    proxyDelegate = (id<NgNotificationProxySubscriberDelegate>)internal;
    threadObject = internal.thread;
  }
  else
  {
    NSAssert1(NO, @"Invalid event thread: %d", thread);
  }

  NgNotificationProxySubscriber * proxy = [NgNotificationProxySubscriber subscriberWithTarget:target selector:selector targetThread:threadObject name:name object:object];
  proxy.delegate = proxyDelegate;
  [[NSNotificationCenter defaultCenter] addObserver:proxy selector:@selector(invoke:) name:name object:object];
  
  [_lock lock];
  [_subscribers addObject:proxy];
  [_lock unlock];
}

#pragma mark Subscription
- (void)addObserver:(id)observer
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object
{
  [self addObserver:observer
           selector:selector
               name:name
             object:object
             thread:NgNotificationProxyThreadCurrent
         threadName:nil];
}
- (void)addObserver:(id)observer
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object
             thread:(NgNotificationProxyThread)thread
{
  [self addObserver:observer
           selector:selector
               name:name
             object:object
             thread:thread
         threadName:nil];
}
- (void)addObserver:(id)observer
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object
         threadName:(NSString *)threadName
{
  [self addObserver:observer
           selector:selector
               name:name
             object:object
             thread:NgNotificationProxyThreadUserDefined
         threadName:threadName];
}

- (void)removeObserver:(id)target
{
  [_lock lock];
  NSMutableArray * subscribersToRemove = [NSMutableArray array];
  [_subscribers enumerateObjectsUsingBlock:^(NgNotificationProxySubscriber * subscriber, NSUInteger idx, BOOL *stop) {
    if (subscriber.safeTarget == nil || subscriber.safeTarget == target) // subscriber.safeTarget == nil, take the opportunity to clean up
    {
      [subscribersToRemove addObject:subscriber];
      [[NSNotificationCenter defaultCenter] removeObserver:subscriber];
    }
  }];
  [_subscribers removeObjectsInArray:subscribersToRemove];
  [_lock unlock];
}
- (void)removeObserver:(id)target name:(NSString *)name object:(id)object
{
  [_lock lock];
  NSMutableArray * subscribersToRemove = [NSMutableArray array];
  [_subscribers enumerateObjectsUsingBlock:^(NgNotificationProxySubscriber * subscriber, NSUInteger idx, BOOL *stop) {
    if (subscriber.safeTarget == nil ||
        (subscriber.safeTarget == target &&
         [subscriber.name isEqual:name] &&
         (subscriber.object == object || (subscriber.object == nil && object == nil))
         )
        )
    {
      [subscribersToRemove addObject:subscriber];
      [[NSNotificationCenter defaultCenter] removeObserver:subscriber];
    }
  }];
  [_subscribers removeObjectsInArray:subscribersToRemove];
  [_lock unlock];
}
- (void)removeAllObservers {
  [_lock lock];
  [_subscribers enumerateObjectsUsingBlock:^(NgNotificationProxySubscriber * subscriber, NSUInteger idx, BOOL *stop) {
    [[NSNotificationCenter defaultCenter] removeObserver:subscriber];
  }];
  [_subscribers removeAllObjects];
  [_lock unlock];
}
#pragma mark NgNotificationProxySubscriberDelegate
- (void)subscriberDidBecomeInvalid:(NgNotificationProxySubscriber *)subscriber
{
  [[NSNotificationCenter defaultCenter] removeObserver:subscriber];
  [_lock lock];
  [_subscribers removeObject:subscriber];
  [_lock unlock];
}

#pragma mark NgNotificationProxyInternalDelegate
- (void)internal:(NgNotificationProxyInternal *)internal subscriberDidBecomeInvalid:(NgNotificationProxySubscriber *)subscriber
{
  [[NSNotificationCenter defaultCenter] removeObserver:subscriber];
  [_lock lock];
  [_subscribers removeObject:subscriber];
  [_lock unlock];
}
@end
