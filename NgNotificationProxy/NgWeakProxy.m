//
//  NgWeakProxy.m
//  Meiwin
//
//  Created by Meiwin Fu on 12/3/15.
//  Copyright (c) 2015 meiwin. All rights reserved.
//

#import "NgWeakProxy.h"
#import "NgWeakProxySubclass.h"

@interface NgWeakProxy ()
{
  __weak id _target;
}
@end

@implementation NgWeakProxy

- (void)setTarget:(id)target
{
  _target = target;
}

+ (instancetype)proxyWithTarget:(id)target
{
  NgWeakProxy * proxy = [[self alloc] init];
  proxy.target = target;
  return proxy;
}

- (id)safeTarget
{
  __strong id strongTarget = _target;
  return strongTarget;
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[NgWeakProxy class]])
  {
    return ((NgWeakProxy *)object).safeTarget == self.safeTarget || object == self.safeTarget;
  }
  return NO;
}
@end
