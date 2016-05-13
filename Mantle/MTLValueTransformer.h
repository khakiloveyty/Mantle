//
//  MTLValueTransformer.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"
#import "MTLTransformerErrorHandling.h"

/// A block that represents a transformation.
///
/// value   - The value to transform.
/// success - The block must set this parameter to indicate whether the
///           transformation was successful.
///           MTLValueTransformer will always call this block with *success
///           initialized to YES.
/// error   - If not NULL, this may be set to an error that occurs during
///           transforming the value.
///
/// Returns the result of the transformation, which may be nil.
typedef id _Nullable MANTLE_DEPRECATED("Unsafe for generics") (^MTLValueTransformerBlock)(_Nullable __kindof id value, BOOL *_Nonnull success, NSError *_Nullable *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

///
/// A value transformer supporting block-based transformation.
///
NS_REFINED_FOR_SWIFT
@interface MTLValueTransformer<__covariant InType, OutType>: NSValueTransformer <MTLTransformerErrorHandling>

/// Returns a transformer which transforms values using the given block. Reverse
/// transformations will not be allowed.
+ (MTLValueTransformer<InType, OutType> *)transformerUsingForwardBlock:(OutType _Nullable (^)(_Nullable __kindof InType value, BOOL *_Nonnull success, NSError *_Nullable *_Nullable error))transformation;

/// Returns a transformer which transforms values using the given block, for
/// forward or reverse transformations.
+ (MTLValueTransformer<InType, InType> *)transformerUsingReversibleBlock:(InType _Nullable (^)(_Nullable __kindof InType value, BOOL *_Nonnull success, NSError *_Nullable *_Nullable error))transformation;

/// Returns a transformer which transforms values using the given blocks.
+ (MTLValueTransformer<InType, OutType> *)transformerUsingForwardBlock:(OutType _Nullable (^)(_Nullable __kindof InType value, BOOL *_Nonnull success, NSError *_Nullable *_Nullable error))forwardTransformation reverseBlock:(InType _Nullable (^)(_Nullable __kindof InType value, BOOL *_Nonnull success, NSError *_Nullable *_Nullable error))reverseTransformation;

@end

@interface MTLValueTransformer (Deprecated)

+ (NSValueTransformer *)transformerWithBlock:(id (^)(id))transformationBlock MANTLE_DEPRECATED("Replaced by +transformerUsingForwardBlock:");

+ (NSValueTransformer *)reversibleTransformerWithBlock:(id (^)(id))transformationBlock MANTLE_DEPRECATED("Replaced by +transformerUsingReversibleBlock:");

+ (NSValueTransformer *)reversibleTransformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock MANTLE_DEPRECATED("Replaced by +transformerUsingForwardBlock:reverseBlock:");

@end

NS_ASSUME_NONNULL_END
