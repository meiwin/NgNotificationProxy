//
//  WeakProxySubclass.h
//  Pie
//
//  Created by Meiwin Fu on 7/11/14.
//  Copyright (c) 2014 Piethis Pte Ltd. All rights reserved.
//

#import "NgWeakProxy.h"

#ifndef NgNotificationProxy_NgProxySubclass_h
#define NgNotificationProxy_NgProxySubclass_h

@interface NgWeakProxy (Subclass)
- (void)setTarget:(id)target;
@end

#endif
