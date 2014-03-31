//
//  MTLReflection.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

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
extern SEL MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) __attribute__((overloadable, pure, nonnull(2, 3)));
extern SEL MTLSelectorWithKeyPattern(const char *prefix, const char *key, const char *suffix) __attribute__((overloadable, pure, nonnull(2, 3)));
