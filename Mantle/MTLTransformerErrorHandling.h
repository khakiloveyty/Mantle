//
//  MTLTransformerErrorHandling.h
//  Mantle
//
//  Created by Robert Böhnke on 10/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// The domain for errors originating from the MTLTransformerErrorHandling
/// protocol.
///
/// Transformers conforming to this protocol are expected to use this error
/// domain if the transformation fails.
extern NS_SWIFT_UNAVAILABLE("Use MTLValueTransformerError") NSString * const MTLTransformerErrorHandlingErrorDomain;

/// Used to indicate that the input value was illegal.
///
/// Transformers conforming to this protocol are expected to use this error code
/// if the transformation fails due to an invalid input value.
extern NS_SWIFT_UNAVAILABLE("Use MTLValueTransformerError.InvalidInput") const NSInteger MTLTransformerErrorHandlingErrorInvalidInput;

/// Associated with the invalid input value.
///
/// Transformers conforming to this protocol are expected to associate this key
/// with the invalid input in the userInfo dictionary.
extern NS_SWIFT_UNAVAILABLE("Use MTLValueTransformerError.InvalidInput") NSString * const MTLTransformerErrorHandlingInputValueErrorKey;

/// Associated with the NSException that was caught.
extern NSString * const MTLTransformerErrorHandlingThrownExceptionErrorKey MANTLE_UNAVAILABLE("Use MTLModelThrownExceptionErrorKey");

/// This protocol can be implemented by NSValueTransformer subclasses to
/// communicate errors that occur during transformation.
@protocol MTLTransformerErrorHandling <NSObject>
@required

/// Transforms a value, returning any error that occurred during transformation.
///
/// value   - The value to transform.
/// success - If not NULL, this will be set to a boolean indicating whether the
///           transformation was successful.
/// error   - If not NULL, this may be set to an error that occurs during
///           transforming the value.
///
/// Returns the result of the transformation which may be nil. Clients should
/// inspect the success parameter to decide how to proceed with the result.
- (nullable id)transformedValue:(nullable id)value success:(BOOL *)success error:(NSError **)error NS_SWIFT_NOTHROW;

@optional

/// Reverse-transforms a value, returning any error that occurred during
/// transformation.
///
/// Transformers conforming to this protocol are expected to implemented this
/// method if they support reverse transformation.
///
/// value   - The value to transform.
/// success - If not NULL, this will be set to a boolean indicating whether the
///           transformation was successful.
/// error   - If not NULL, this may be set to an error that occurs during
///           transforming the value.
///
/// Returns the result of the reverse transformation which may be nil. Clients
/// should inspect the success parameter to decide how to proceed with the
/// result.
- (nullable id)reverseTransformedValue:(nullable id)value success:(BOOL *)success error:(NSError **)error NS_SWIFT_NOTHROW;

@end

@interface NSValueTransformer (MTLTransformerErrorHandling) <MTLTransformerErrorHandling>
@end

NS_ASSUME_NONNULL_END
