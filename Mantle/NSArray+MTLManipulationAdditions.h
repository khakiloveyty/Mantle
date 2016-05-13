//
//  NSArray+MTLManipulationAdditions.h
//  Mantle
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<ObjectType> (MTLManipulationAdditions)

/// Returns a new array without all instances of the given object.
- (NSArray<ObjectType> *)mtl_arrayByRemovingObject:(ObjectType)object NS_SWIFT_UNAVAILABLE("Use methods on Array");

/// Returns a new array without the first object. If the array is empty, it
/// returns the empty array.
- (NSArray<ObjectType> *)mtl_arrayByRemovingFirstObject NS_SWIFT_UNAVAILABLE("Use Array.dropFirst()");

/// Returns a new array without the last object. If the array is empty, it
/// returns the empty array.
- (NSArray<ObjectType> *)mtl_arrayByRemovingLastObject NS_SWIFT_UNAVAILABLE("Use Array.dropLast()");

@end

NS_ASSUME_NONNULL_END
