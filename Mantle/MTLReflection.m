//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
#import <objc/runtime.h>

SEL __attribute__((overloadable)) MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) {
	return MTLSelectorWithKeyPattern(prefix, key.UTF8String, suffix);
}

SEL __attribute__((overloadable)) MTLSelectorWithKeyPattern(const char *prefix, const char *key, const char *suffix) {
	size_t prefixLength = prefix ? strlen(prefix) : 0;
	size_t suffixLength = strlen(suffix);

	char initial = key[0];
	if (prefixLength) initial = (char)toupper(initial);
	size_t initialLength = 1;

	const char *rest = key + initialLength;
	size_t restLength = strlen(rest);

	char selector[prefixLength + initialLength + restLength + suffixLength + 1];
	memcpy(selector, prefix, prefixLength);
	selector[prefixLength] = initial;
	memcpy(selector + prefixLength + initialLength, rest, restLength);
	memcpy(selector + prefixLength + initialLength + restLength, suffix, suffixLength);
	selector[prefixLength + initialLength + restLength + suffixLength] = '\0';

	return sel_registerName(selector);
}

static void *MTLCachedPropertyKeysSharedKeySetKey = &MTLCachedPropertyKeysSharedKeySetKey;
static void *MTLCachedPropertyKeysEnumerableKey = &MTLCachedPropertyKeysEnumerableKey;

static id MTLGetPropertyKeysSharedKeySet(Class <MTLModel> cls)
{
	id sharedPropertyKeySet = objc_getAssociatedObject(cls, MTLCachedPropertyKeysSharedKeySetKey);
	if (sharedPropertyKeySet != nil) return sharedPropertyKeySet;

	sharedPropertyKeySet = [NSMutableDictionary sharedKeySetForKeys:[[cls propertyKeys] allObjects]];

	objc_setAssociatedObject(cls, MTLCachedPropertyKeysSharedKeySetKey, sharedPropertyKeySet, OBJC_ASSOCIATION_COPY);

	return sharedPropertyKeySet;
}

id <NSFastEnumeration> MTLGetPropertyKeysEnumerable(Class <MTLModel> cls)
{
	id sharedKeySet = MTLGetPropertyKeysSharedKeySet(cls);
	if ([sharedKeySet conformsToProtocol:@protocol(NSFastEnumeration)]) {
		return sharedKeySet;
	} else {
		return [cls propertyKeys];
	}
}

NSDictionary *MTLCopyPropertyKeyMapUsingBlock(Class <MTLModel> cls, id(^block)(NSString *propertyName, BOOL *stop))
{
	NSMutableDictionary *result = nil;

	id sharedKeySet = MTLGetPropertyKeysSharedKeySet(cls);
	if (sharedKeySet) {
		result = [NSMutableDictionary dictionaryWithSharedKeySet:sharedKeySet];
	} else {
		result = [NSMutableDictionary dictionary];
	}

	for (NSString *key in MTLGetPropertyKeysEnumerable(cls)) {
		BOOL stop = NO;
		id value = block(key, &stop);

		if (stop) {
			return nil;
		}

		if (value) {
			result[key] = value;
		}
	}

	return [result copy];
}
