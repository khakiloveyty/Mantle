//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
@import ObjectiveC.runtime;

void MTLEnumeratePropertiesUsingBlock(Class fromCls, Class toCls, void(^block)(NSString *propertyName)) {
    if (fromCls == NULL || block == NULL) return;
    if (toCls == NULL) toCls = [fromCls superclass];
    
    Class thisCls = fromCls;
    while (thisCls != NULL && thisCls != toCls && thisCls != NSObject.class) {
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(thisCls, &count);
        
        if (properties) {
            for (unsigned int i = 0; i < count; i++) {
                const char *propertyName = property_getName(properties[i]);
                NSString *name = [[NSString alloc] initWithBytesNoCopy:(void *)propertyName length:strlen(propertyName) encoding:NSUTF8StringEncoding freeWhenDone:NO];
                block(name);
            }
            
            free(properties);
        }
        
        thisCls = [thisCls superclass];
    };
}

MTLPropertyAttributes MTLGetAttributesForProperty(Class __unused cls, NSString *__unused propertyName) {
    const char *name = NULL;
    BOOL readonly = NO, nonatomic = NO, dynamic = NO, hasIvar = NO, isObjectType = NO;
    MTLPropertyMemoryPolicy memoryPolicy = MTLPropertyMemoryPolicyAssign;
    Class objectClass = Nil;
    
    objc_property_t property = class_getProperty(cls, propertyName.UTF8String);
    if (property) {
        name = property_getName(property);
        
        const char *const attrString = property_getAttributes(property);
        NSCAssert(attrString, @"Could not get attribute string from property %s.", name);
        NSCAssert(attrString[0] == 'T', @"Expected attribute string \"%s\" for property %s to start with 'T'.", attrString, name);
        
        const char *typeString = attrString + 1;
        const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
        NSCAssert(next, @"Could not read past type in attribute string \"%s\" for property %s.", attrString, name);
        
        size_t typeLength = next - typeString;
        NSCAssert(typeLength, @"Invalid type in attribute string \"%s\" for property %s.", attrString, name);
        
        BOOL isObject = (typeString[0] == *(@encode(id)) || typeString[0] == *(@encode(Class)));
        // if this is an object type, and immediately followed by a quoted string...
        if (isObject && typeString[1] == '"') {
            isObjectType = YES;
            // we should be able to extract a class name
            const char *className = typeString + 2;
            next = strchr(className, '"');
            
            NSCAssert(next, @"Could not read class name in attribute string \"%s\" for property %s.", attrString, name);
            
            if (className != next) {
                size_t classNameLength = next - className;
                char trimmedName[classNameLength + 1];
                
                strncpy(trimmedName, className, classNameLength);
                trimmedName[classNameLength] = '\0';
                
                // attempt to look up the class in the runtime
                objectClass = objc_getClass(trimmedName);
            }
        } else {
            isObjectType = isObject;
        }
        
        if (*next != '\0') {
            // skip past any junk before the first flag
            next = strchr(next, ',');
        }
        
        while (next && *next == ',') {
            char flag = next[1];
            next += 2;
            
            switch (flag) {
                case '\0':
                    break;
                    
                case 'R':
                    readonly = YES;
                    break;
                    
                case 'C':
                    memoryPolicy = MTLPropertyMemoryPolicyCopy;
                    break;
                    
                case '&':
                    memoryPolicy = MTLPropertyMemoryPolicyRetain;
                    break;
                    
                case 'N':
                    nonatomic = YES;
                    break;
                    
                case 'G':
                case 'S':
                {
                    // getter and setter
                    const char *nextFlag = strchr(next, ',');
                    if (!nextFlag) {
                        next = "";
                    } else {
                        next = nextFlag;
                    }
                    break;
                }
                    
                case 'D':
                    dynamic = YES;
                    break;
                    
                case 'V':
                    // assume that the rest of the string (if present) is the ivar name
                    // otherwise assume it is dynamic
                    if (*next != '\0') {
                        hasIvar = YES;
                        next = "";
                    }
                    
                    break;
                    
                case 'W':
                    memoryPolicy = MTLPropertyMemoryPolicyWeak;
                    break;
                    
                case 'P':
                    // can be garbage collected
                    break;
                    
                case 't':
                    NSCAssert(NO, @"Old-style type encoding is unsupported in attribute string \"%s\" for property %s.", attrString, name);
                    
                    // skip over this type encoding
                    while (*next != ',' && *next != '\0')
                        ++next;
                    
                    break;
                    
                default:
                    NSCAssert(NO, @"Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s.", flag, attrString, name);
                    break;
            }
        }
    }
    
    return (MTLPropertyAttributes){
        .name = name,
        .readonly = readonly,
        .nonatomic = nonatomic,
        .dynamic = dynamic,
        .memoryPolicy = memoryPolicy,
        .hasIvar = hasIvar,
        .isObjectType = isObjectType,
        .objectClass = objectClass
    };
}

SEL MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) {
    NSUInteger prefixLength = strlen(prefix);
	NSUInteger suffixLength = strlen(suffix);

	NSString *initial = [[key substringToIndex:1] uppercaseString];
	NSUInteger initialLength = [initial maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	NSString *rest = [key substringFromIndex:1];
	NSUInteger restLength = [rest maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	char selector[prefixLength + initialLength + restLength + suffixLength + 1];
	memcpy(selector, prefix, prefixLength);

    if (![initial getBytes:selector + prefixLength maxLength:initialLength usedLength:&initialLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, initial.length) remainingRange:NULL]) {
        return NULL;
    }

    if (![rest getBytes:selector + prefixLength + initialLength maxLength:restLength usedLength:&restLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, rest.length) remainingRange:NULL]) {
        return NULL;
    }

	memcpy(selector + prefixLength + initialLength + restLength, suffix, suffixLength);
	selector[prefixLength + initialLength + restLength + suffixLength] = '\0';

	return sel_registerName(selector);
}

static id MTLGetPropertyKeysSharedKeySet(Class <MTLModel> cls) {
    static void *MTLCachedPropertyKeysSharedKeySetKey = &MTLCachedPropertyKeysSharedKeySetKey;

    id sharedPropertyKeySet = objc_getAssociatedObject(cls, MTLCachedPropertyKeysSharedKeySetKey);
	if (sharedPropertyKeySet != nil) return sharedPropertyKeySet;
	
	sharedPropertyKeySet = [NSMutableDictionary sharedKeySetForKeys:[[cls propertyKeys] allObjects]];
	
	objc_setAssociatedObject(cls, MTLCachedPropertyKeysSharedKeySetKey, sharedPropertyKeySet, OBJC_ASSOCIATION_COPY);
	
	return sharedPropertyKeySet;
}

id <NSFastEnumeration> MTLGetPropertyKeysEnumerable(Class <MTLModel> cls) {
	id sharedKeySet = MTLGetPropertyKeysSharedKeySet(cls);
	if ([sharedKeySet conformsToProtocol:@protocol(NSFastEnumeration)]) {
		return sharedKeySet;
	}
	return [cls propertyKeys];
}

NSDictionary *MTLCopyPropertyKeyMapUsingBlock(Class <MTLModel> cls, id(^block)(NSString *, BOOL *)) {
	__block NSMutableDictionary *result = nil;
    void(^populate)(void) = ^{
        BOOL stop = NO;
        
        for (NSString *key in MTLGetPropertyKeysEnumerable(cls)) {
            id value = block(key, &stop);
            
            if (stop) {
                result = nil;
                return;
            }
            
            if (value) { result[key] = value; }
        }
    };
	
	id sharedKeySet = MTLGetPropertyKeysSharedKeySet(cls);
	if (sharedKeySet) {
		result = [NSMutableDictionary dictionaryWithSharedKeySet:sharedKeySet];
        populate();
        return result;
	}
    
    result = [NSMutableDictionary dictionary];
    populate();
    return [result copy];
}
