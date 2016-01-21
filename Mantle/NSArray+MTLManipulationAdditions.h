//
//  NSArray+MTLManipulationAdditions.h
//  Mantle
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (MTLManipulationAdditions)

/// Returns a new array without all instances of the given object.
- (NSArray *)mtl_arrayByRemovingObject:(id)object;

/// Returns a new array without the first object. If the array is empty, it
/// returns the empty array.
- (NSArray *)mtl_arrayByRemovingFirstObject;

/// Returns a new array without the last object. If the array is empty, it
/// returns the empty array.
- (NSArray *)mtl_arrayByRemovingLastObject;

@end
