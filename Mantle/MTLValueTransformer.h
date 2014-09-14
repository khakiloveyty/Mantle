//
//  MTLValueTransformer.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@import Foundation;

// The domain for errors originating from the MTLTransformerErrorHandling
// protocol.
//
// Transformers conforming to this protocol are expected to use this error
// domain if the transformation fails.
extern NSString *const MTLTransformerErrorHandlingErrorDomain;

// Used to indicate that the input value was illegal.
//
// Transformers conforming to this protocol are expected to use this error code
// if the transformation fails due to an invalid input value.
extern const NSInteger MTLTransformerErrorHandlingErrorInvalidInput;

// Associated with the invalid input value.
//
// Transformers conforming to this protocol are expected to associate this key
// with the invalid input in the userInfo dictionary.
extern NSString *const MTLTransformerErrorHandlingInputValueErrorKey;

// A block that represents a transformation.
//
// value   - The value to transform.
// success - The block must set this parameter to indicate whether the
//           transformation was successful.
//           MTLValueTransformer will always call this block with *success
//           initialized to YES.
// error   - If not NULL, this may be set to an error that occurs during
//           transforming the value.
//
// Returns the result of the transformation, which may be nil.
typedef id (^MTLValueTransformerBlock)(id value, BOOL *success, NSError **error);

// This protocol can be implemented by NSValueTransformer subclasses to
// communicate errors that occur during transformation.
@protocol MTLTransformerErrorHandling <NSObject>
@required

// Transforms a value, returning any error that occurred during transformation.
//
// value   - The value to transform.
// success - If not NULL, this will be set to a boolean indicating whether the
//           transformation was successful.
// error   - If not NULL, this may be set to an error that occurs during
//           transforming the value.
//
// Returns the result of the transformation which may be nil. Clients should
// inspect the success parameter to decide how to proceed with the result.
- (id)transformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@optional

// Reverse-transforms a value, returning any error that occurred during
// transformation.
//
// Transformers conforming to this protocol are expected to implemented this
// method if they support reverse transformation.
//
// value   - The value to transform.
// success - If not NULL, this will be set to a boolean indicating whether the
//           transformation was successful.
// error   - If not NULL, this may be set to an error that occurs during
//           transforming the value.
//
// Returns the result of the reverse transformation which may be nil. Clients
// should inspect the success parameter to decide how to proceed with the
// result.
- (id)reverseTransformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@end

@interface NSValueTransformer (MTLValueTransformer)

// Flips the direction of the receiver's transformation, such that
// -transformedValue: will become -reverseTransformedValue:, and vice-versa.
//
// The receiver must allow reverse transformation.
//
// Returns an inverted transformer.
- (NSValueTransformer *)mtl_invertedTransformer;

@end

//
// A value transformer supporting block-based transformation.
//
@interface MTLValueTransformer : NSValueTransformer <MTLTransformerErrorHandling>

// Returns a transformer which transforms values using the given block. Reverse
// transformations will not be allowed.
+ (instancetype)transformerUsingForwardBlock:(MTLValueTransformerBlock)transformation;

// Returns a transformer which transforms values using the given block, for
// forward or reverse transformations.
+ (instancetype)transformerUsingReversibleBlock:(MTLValueTransformerBlock)transformation;

// Returns a transformer which transforms values using the given blocks.
+ (instancetype)transformerUsingForwardBlock:(MTLValueTransformerBlock)forwardTransformation reverseBlock:(MTLValueTransformerBlock)reverseTransformation;

@end
