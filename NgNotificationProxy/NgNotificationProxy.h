//
//  NgNotificationProxy.h
//  Meiwin
//
//  Created by Meiwin Fu on 12/3/15.
//  Copyright (c) 2015 meiwin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint32_t, NgNotificationProxyThread) {
  NgNotificationProxyThreadCurrent = 0,
  NgNotificationProxyThreadMain,
  NgNotificationProxyThreadBackground
};

/**
 *
 * `NgNotificationProxy` is proxy to observing notifications (posted with `NSNotificationCenter`).
 * It allows user of the API to specify target thread to which `selector` of `observer` to be called.
 * Additionally it also prevents crashes that would normally happen if object doesn't remove itself
 * from observing.
 *
 * Following are kind of threads user could specify:
 * - NgNotificationProxyThreadCurrent, invoked in the same thread as thread from which notification was posted. This is the default when not specified.
 * - NgNotificationProxyThreadMain, invoked in main thread.
 * - NgNotificationProxyThreadBackground, invoked in `NgNotificationProxy` background thread.
 * - User defined (by name).
 *
 */
@interface NgNotificationProxy : NSObject

+ (instancetype)defaultProxy;

- (void)addObserver:(id)observer
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object;

- (void)addObserver:(id)observer
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object
             thread:(NgNotificationProxyThread)thread;

- (void)addObserver:(id)observer
           selector:(SEL)selector
               name:(NSString *)name
             object:(id)object
         threadName:(NSString *)threadName;

- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(NSString *)name object:(id)object;

@end
