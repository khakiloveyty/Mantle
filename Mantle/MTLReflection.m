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
