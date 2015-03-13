//
//  NgNotificationProxyTests.m
//  NgNotificationProxy
//
//  Created by Meiwin Fu on 13/3/15.
//  Copyright (c) 2015 Meiwin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NgNotificationProxy.h"

@interface NgNotificationProxyTests : XCTestCase
{
  XCTestExpectation * _expectation;
  NSThread * _currentThread;
}
@end

@implementation NgNotificationProxyTests

- (void)setUp {

  [super setUp];
  
  // Put setup code here. This method is called before the invocation of each test method in the class.
  _expectation = nil;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  [[NgNotificationProxy defaultProxy] removeObserver:self];
  
  [super tearDown];
}
- (void)postFulfill
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    _currentThread = [NSThread currentThread];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fulfill" object:self];
  });
}

#pragma mark Main Thread
- (void)testForMainThread
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillMainThread)
                                             name:@"fulfill"
                                           object:nil
                                           thread:NgNotificationProxyThreadMain];
  
  _expectation = [self expectationWithDescription:@"main thread 1"];
  [self postFulfill];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)testForMainThreadWithObject
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillMainThread)
                                             name:@"fulfill"
                                           object:self
                                           thread:NgNotificationProxyThreadMain];
  
  _expectation = [self expectationWithDescription:@"main thread 2"];
  [self postFulfill];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)fulfillMainThread
{
  XCTAssert([NSThread isMainThread]);
  [_expectation fulfill];
}

#pragma mark Background Thread
- (void)testForBackgroundThread
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillBackgroundThread)
                                             name:@"fulfill"
                                           object:nil
                                           thread:NgNotificationProxyThreadBackground];

  _expectation = [self expectationWithDescription:@"background thread 1"];
  [self postFulfill];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)testForBackgroundThreadWithObject
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillBackgroundThread)
                                             name:@"fulfill"
                                           object:self
                                           thread:NgNotificationProxyThreadBackground];
  
  _expectation = [self expectationWithDescription:@"background thread 2"];
  [self postFulfill];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)fulfillBackgroundThread
{
  XCTAssertEqualObjects([NSThread currentThread].name, @"NgNotificationProxy.internal.background");
  [_expectation fulfill];
}

#pragma mark User Defined Thread
- (void)testForUserDefinedThread
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillUserDefinedThread)
                                             name:@"fulfill"
                                           object:nil
                                       threadName:@"user-thread"];

  _expectation = [self expectationWithDescription:@"user defined 1"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self postFulfill];
  });
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testForUserDefinedThreadWithObject
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillUserDefinedThread)
                                             name:@"fulfill"
                                           object:self
                                       threadName:@"user-thread"];
  
  _expectation = [self expectationWithDescription:@"user defined 2"];
  [self postFulfill];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)fulfillUserDefinedThread
{
  XCTAssertEqualObjects([NSThread currentThread].name, @"user-thread");
  [_expectation fulfill];
}

#pragma mark Current Thread
- (void)testForCurrentThread
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillCurrentThread)
                                             name:@"fulfill"
                                           object:nil
                                           thread:NgNotificationProxyThreadCurrent];
  
  _expectation = [self expectationWithDescription:@"current thread 1"];
  [self postFulfill];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)testForCurrentThreadWithObject
{
  [[NgNotificationProxy defaultProxy] addObserver:self
                                         selector:@selector(fulfillCurrentThread)
                                             name:@"fulfill"
                                           object:self
                                           thread:NgNotificationProxyThreadCurrent];
  
  _expectation = [self expectationWithDescription:@"current thread 2"];
  [self postFulfill];
  
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)fulfillCurrentThread
{
  XCTAssertEqualObjects([NSThread currentThread], _currentThread);
  [_expectation fulfill];
}
@end
