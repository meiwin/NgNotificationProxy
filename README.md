[![Build Status](https://travis-ci.org/meiwin/NgNotificationProxy.svg)](https://travis-ci.org/meiwin/NgNotificationProxy)

# NgNotificationProxy

NgNotificationProxy is simple proxy implementation for observing notification posted with `NSNotificationCenter`.

## Adding to your project

```ruby
pod NgNotificationProxy
```

To manually add to your projects:

1. Add `NgWeakProxy.h`, `NgWeakProxy.m`, `NgWeakProxySubclass.h`, `NgNotificationProxy.h` and `NgNotificationProxy.m` to your project.

NgNotificationProxy requires ARC.

## Features

NgNotificationProxy is built to make delivering notifications to particular threads a trivial task.
See [Delivering Notifications to Particular Threads](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Notifications/Articles/Threading.html#//apple_ref/doc/uid/20001289-CEGJFDFG).

In addition, NgNotificationProxy also detects if an observer reference is invalid and stop observing for notifications automatically (instead of crashing).

With NgNotificationProxy, you can specify target thread to which notification is delivered:
- `NgNotificationProxyThreadCurrent`, deliver notifications to the same thread as where it is posted. This is default thread if not specified.
- `NgNotificationProxyThreadMain`, deliver notifications to main thread.
- `NgNotificationProxyThreadBackground`, deliver notifications to NgNotificationProxy's background thread (thread name: `NgNotificationProxy.internal.background`).
- Any other user-defined thread name.

## Working with NgNotificationProxy

Deliver notifications to current thread.

```objective-c
[[NgNotificationProxy defaultProxy] addObserver:self 
                                       selector:@selector(onNotification:) 
                                           name:@"NotificationName" 
                                          object:nil];
```

Deliver notifications to main thread.

```objective-c
[[NgNotificationProxy defaultProxy] addObserver:self 
                                       selector:@selector(onNotification:) 
                                           name:@"NotificationName" 
                                         object:nil 
                                         thread:NgNotificationProxyThreadMain];
```

Deliver notifications to background thread.

```objective-c
[[NgNotificationProxy defaultProxy] addObserver:self 
                                       selector:@selector(onNotification:) 
                                           name:@"NotificationName" 
                                         object:nil 
                                         thread:NgNotificationProxyThreadBackground];
```

Deliver notifications to user-defined thread.

```objective-c
[[NgNotificationProxy defaultProxy] addObserver:self 
                                       selector:@selector(onNotification:) 
                                           name:@"NotificationName" 
                                         object:nil 
                                     threadName:@"MyThread"];
```

Stop observing notifications.

```objective-c
[[NgNotificationProxy defaultProxy] removeObserver:self];
```

or

```objective-c
[[NgNotificationProxy defaultProxy] removeObserver:self 
                                              name:@"NotificationName" 
                                            object:nil];
```

## Benefits

NgNotificationProxy gives you better control and writing cleaner code.
One of the most common use case is to deliver notification to main thread for performing UI updates as result of an event.

With `NSNotificationCenter`.

```objective-c
// observing notification
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(updateUI:) 
                                             name:kUIDataUpdateNotification 
                                           object:nil];


// updateUI implementation.
- (void)updateUI:(NSNotification *)notification
{
  dispatch_async(dispatch_get_main_queue(), ^{ // ensure `reloadData` always execute in main-thread
     [self reloadData];
  });
}
```

With `NgNotificationProxy`.

```objective-c
// observing notification
[[NgNotificationProxy defaultProxy] addObserver:self
                                       selector:@selector(updateUI:) 
                                           name:kUIDataUpdateNotification 
                                         object:nil
                                         thread:NgNotificationProxyThreadMain];

// updateUI implementation
- (void)updateUI:(NSNotification *)notification
{
  [self reloadData];
}
```
