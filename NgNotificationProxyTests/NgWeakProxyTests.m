//
//  NgWeakProxyTests.m
//  NgNotificationProxy
//
//  Created by Meiwin Fu on 13/3/15.
//  Copyright (c) 2015 Meiwin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NgWeakProxy.h"

@interface NgWeakProxyTests : XCTestCase

@end

@implementation NgWeakProxyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testWeakProxy
{
  NgWeakProxy * proxy = nil;
  @autoreleasepool {

    NSObject * obj = [NSObject new];
    proxy = [NgWeakProxy proxyWithTarget:obj];
    
    XCTAssertNotNil(proxy.safeTarget);
  };
  
  XCTAssertNil(proxy.safeTarget);  
}

@end
