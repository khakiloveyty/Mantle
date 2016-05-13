//
//  NSError+MTLModelException.h
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError (MTLModelException)

/// Creates a new error for an exception that occurred during updating an
/// MTLModel.
///
/// exception - The exception that was thrown while updating the model.
/// description - Localized description for the error.
///
/// Returns an error that takes its localized description and failure reason
/// from the exception. If a localized description is also included, the
/// exception description is used as the recovery suggestion.
- (instancetype)mtl_initWithModelException:(NSException *)exception localizedDescription:(nullable NSString *)description MANTLE_EXTENDED_INIT;

@end

NS_ASSUME_NONNULL_END
