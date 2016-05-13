//
//  NSKeyValueCoding+MTLValidationAdditions.h
//  Mantle
//
//  Created by Zachary Waldowski on 5/10/16.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

NS_ASSUME_NONNULL_BEGIN

// Validates a value for an object and sets it if necessary.
//
// obj         - The object for which the value is being validated.
// key         - The name of one of `obj`s properties.
// value       - The new value for the property identified by `key`.
// forceUpdate - If set to `YES`, the value is being updated even if validating
//               it did not change it.
// error       - If not NULL, this may be set to any error that occurs during
//               validation.
//
// Returns YES if `value` could be validated and set, or NO if an error
// occurred.
MANTLE_PRIVATE
BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError *_Nullable *_Nullable error);

NS_ASSUME_NONNULL_END
