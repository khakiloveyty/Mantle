//
//  MTLReflection.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"

// Creates a selector from a key and a constant prefix and suffix.
//
// prefix - An optional string to prepend to the key as part of the selector.
// key    - The key to insert into the generated selector. This key should be in
//          its natural case; if prefixed, it will have its first letter
//          capitalized.
// suffix - A string to append to the key as part of the selector.
//
// Returns a selector, or NULL if the input strings cannot form a valid
// selector.
SEL MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) __attribute__((pure, nonnull(2, 3)));

// Enumerable object representing the property keys of the given model class.
//
// Enumerating using the returned object will be at best be more efficient than
// just enumerating through the +propertyKeys of the given model class.
//
// class - A class conforming to MTLModel.
//
// Returns an object conforming to the NSFastEnumeration protocol.
extern id <NSFastEnumeration> MTLGetPropertyKeysEnumerable(Class <MTLModel> cls);

// Creates mapping from property keys to a given value.
//
// This function will be more efficient than the manual creation of a dictionary
// with the property keys of the given model class.
//
// class - A class conforming to MTLModel.
//
// Returns a dictionary that maps all properties of the given class to
// the results of the given block.
extern NSDictionary *MTLCopyPropertyKeyMapUsingBlock(Class <MTLModel> cls, id(^block)(NSString *propertyName, BOOL *stop)) __attribute__((nonnull(2)));
