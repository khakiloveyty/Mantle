//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
@import ObjectiveC.runtime;

SEL MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) {
	NSUInteger prefixLength = prefix ? strlen(prefix) : 0;
	NSUInteger keyLength = [key maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger suffixLength = suffix ? strlen(suffix) : 0;

	char selector[prefixLength + keyLength + suffixLength + 1];
	memcpy(selector, prefix, prefixLength);

	if (![key getBytes:selector + prefixLength maxLength:keyLength usedLength:&keyLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, key.length) remainingRange:NULL]) {
        return NULL;
    }

	if (prefixLength != 0) {
		selector[prefixLength] = (char)toupper(selector[prefixLength]);
	}

	memcpy(selector + prefixLength + keyLength, suffix, suffixLength);
	selector[prefixLength + keyLength + suffixLength] = '\0';

	return sel_registerName(selector);
}

NSString *MTLTypeEncodingForProperty(Class cls, NSString *propertyName, Class *outClass) {
	objc_property_t property = class_getProperty(cls, propertyName.UTF8String);
	if (property == NULL) {
		if (outClass != NULL) { *outClass = Nil; }
		return nil;
	}

	char *typeString = property_copyAttributeValue(property, "T");
	if (typeString == NULL) {
		if (outClass != NULL) { *outClass = Nil; }
		return nil;
	}

	if (outClass == NULL) {
		return [[NSString alloc] initWithBytesNoCopy:typeString length:strlen(typeString) encoding:NSUTF8StringEncoding freeWhenDone:YES];
	}

	NSString *ret = @(typeString);
	do {
		// parse "@\"NSString\""
		const char *className = NULL;
		char *decodeString = typeString;

		// skip opening sigil
		if (*decodeString != _C_ID) { break; }
		++decodeString;
		if (*decodeString != '"') { break; }
		++decodeString;

		className = decodeString;

		while (*decodeString != '"' && *decodeString != '\0') {
			++decodeString;
		}
		*decodeString = '\0';

		if (className == NULL) { break; }
		*outClass = objc_getClass(className);
	} while (0);

	free(typeString);

	return ret;
}

NS_INLINE SEL MTLPropertyAttributesGetSelector(const char *_Nonnull *_Nonnull next) {
	const char *nextFlag = strchr(*next, ',');

	if (nextFlag == NULL) {
		// assume that the rest of the string is the selector
		const char *selectorString = *next;
		*next = "";

		return sel_registerName(selectorString);
	}

	size_t selectorLength = nextFlag - *next;
	if (!selectorLength) {
		return NULL;
	}

	char selectorString[selectorLength + 1];
	strncpy(selectorString, *next, selectorLength);
	selectorString[selectorLength] = '\0';

	*next = nextFlag;
	return sel_getUid(selectorString);
}

NS_INLINE SEL MTLPropertyAttributesGetter(objc_property_t property) {
	return sel_registerName(property_getName(property));
}

NS_INLINE SEL MTLPropertyAttributesSetter(NSString *key) {
	return MTLSelectorWithKeyPattern("set", key, ":");
}

mtl_property_attr_t MTLAttributesForProperty(Class cls, NSString *key) {
	objc_property_t property = class_getProperty(cls, key.UTF8String);
	if (property == NULL) { return 0; }

	const char *next = property_getAttributes(property);
	if (next == NULL || *next != 'T') { return 0; }

	// skip past any junk before the first flag
	if (*next != '\0') {
		next = strchr(next, ',');
	}

	mtl_property_attr_t ret = 0;
	BOOL explicitGetter = NO, explicitSetter = NO;

    while (next && *next == ',') {
        char flag = next[1];
        next += 2;

        switch (flag) {
        case '\0':
            break;

        case 'R':
			ret |= mtl_property_readonly;
            break;

		case 'G': {
			SEL getter = MTLPropertyAttributesGetSelector(&next);
			if (getter != NULL && class_respondsToSelector(cls, getter)) {
				explicitGetter = YES;
				ret |= mtl_property_hasGetter;
			}
			break;
		}

        case 'S': {
			SEL setter = MTLPropertyAttributesGetSelector(&next);
			if (setter != NULL && class_respondsToSelector(cls, setter)) {
				explicitSetter = YES;
				ret |= mtl_property_hasSetter;
			}
			break;
		}

        case 'D':
			ret |= mtl_property_dynamic;
			ret &= ~mtl_property_hasIvar;
            break;

        case 'V':
            // assume that the rest of the string (if present) is the ivar name
            if (*next != '\0') {
				ret |= mtl_property_hasIvar;
                next = "";
            }
            break;

        case 'W':
			ret |= mtl_property_weak;
            break;

        default:
			break;
        }
    }

	if (!explicitGetter) {
		// use the property name as the getter by default
		SEL getter = MTLPropertyAttributesGetter(property);
		if (getter != NULL && class_respondsToSelector(cls, getter)) {
			ret |= mtl_property_hasGetter;
		}
	}

	if (!explicitSetter) {
		SEL setter = MTLPropertyAttributesSetter(key);
		if (setter != NULL && class_respondsToSelector(cls, setter)) {
			ret |= mtl_property_hasSetter;
		}
	}

    return ret;
}

#ifdef __APPLE__
#import <libproc.h>

BOOL MTLIsDebugging(void) {
	struct proc_bsdshortinfo info = {};
	int size = sizeof(struct proc_bsdshortinfo);
	if (proc_pidinfo(getpid(), PROC_PIDT_SHORTBSDINFO, 0, &info, size) == PROC_PIDT_SHORTBSDINFO_SIZE) {
		return (info.pbsi_flags & PROC_FLAG_TRACED);
	} else {
		return NO;
	}
}
#endif
