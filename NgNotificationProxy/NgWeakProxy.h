//
//  NgWeakProxy.h
//  Meiwin
//
//  Created by Meiwin Fu on 12/3/15.
//  Copyright (c) 2015 meiwin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NgWeakProxy : NSObject
@property (nonatomic, readonly) id safeTarget;
+ (instancetype)proxyWithTarget:(id)target;
@end
