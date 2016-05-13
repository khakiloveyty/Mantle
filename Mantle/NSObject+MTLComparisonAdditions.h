//
//  NSObject+MTLComparisonAdditions.h
//  Mantle
//
//  Created by Josh Vera on 10/26/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns whether both objects are identical or equal via -isEqual:
extern BOOL MTLEqualObjects(_Nullable id obj1, _Nullable id obj2) NS_SWIFT_UNAVAILABLE("Use ==");

NS_ASSUME_NONNULL_END
