//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
#import <objc/runtime.h>

SEL MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) {
	NSUInteger prefixLength = prefix ? strlen(prefix) : 0;
	NSUInteger suffixLength = strlen(suffix);

	NSString *initial = [key substringToIndex:1];
	if (prefix) {
		initial = initial.uppercaseString;
	}
	NSUInteger initialLength = [initial maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	NSString *rest = [key substringFromIndex:1];
	NSUInteger restLength = [rest maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	char selector[prefixLength + initialLength + restLength + suffixLength + 1];
	memcpy(selector, prefix, prefixLength);

	BOOL success = [initial getBytes:selector + prefixLength maxLength:initialLength usedLength:&initialLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, initial.length) remainingRange:NULL];
	if (!success) return NULL;

	success = [rest getBytes:selector + prefixLength + initialLength maxLength:restLength usedLength:&restLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, rest.length) remainingRange:NULL];
	if (!success) return NULL;

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
	}
	return [cls propertyKeys];
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
