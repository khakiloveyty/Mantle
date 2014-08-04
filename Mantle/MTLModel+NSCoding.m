//
//  MTLModel+NSCoding.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel+NSCoding.h"
#import "MTLPropertyAttributes.h"
#import "MTLReflection.h"
#import <objc/runtime.h>

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MTLModelVersionKey = @"MTLModelVersion";

// Used to cache the reflection performed in +allowedSecureCodingClassesByPropertyKey.
static void *MTLModelCachedAllowedClassesKey = &MTLModelCachedAllowedClassesKey;

// Returns all of the given class' encodable property keys (those that will not
// be excluded from archives).
static NSSet *encodablePropertyKeysForClass(Class modelClass) {
	return [[modelClass encodingBehaviorsByPropertyKey] keysOfEntriesPassingTest:^ BOOL (NSString *__unused propertyKey, NSNumber *behavior, BOOL *__unused stop) {
		return behavior.unsignedIntegerValue != MTLModelEncodingBehaviorExcluded;
	}];
}

// Verifies that all of the specified class' encodable property keys are present
// in +allowedSecureCodingClassesByPropertyKey, and throws an exception if not.
static void verifyAllowedClassesByPropertyKey(Class modelClass) {
	NSDictionary *allowedClasses = [modelClass allowedSecureCodingClassesByPropertyKey];

	NSMutableSet *specifiedPropertyKeys = [[NSMutableSet alloc] initWithArray:allowedClasses.allKeys];
	[specifiedPropertyKeys minusSet:encodablePropertyKeysForClass(modelClass)];

	if (specifiedPropertyKeys.count > 0) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Cannot encode %@ securely, because keys are missing from +%@: %@", modelClass, NSStringFromSelector(@selector(allowedSecureCodingClassesByPropertyKey)), specifiedPropertyKeys] userInfo:nil];
	}
}

@implementation MTLModel (NSCoding)

#pragma mark Versioning

+ (NSUInteger)modelVersion {
	return 0;
}

#pragma mark Encoding Behaviors

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
	return MTLCopyPropertyKeyMapUsingBlock(self, ^id(NSString *key, BOOL *__unused stop) {
		MTLPropertyAttributes *attributes = [MTLPropertyAttributes propertyNamed:key class:self];
		NSAssert(attributes != nil, @"Could not find property \"%@\" on %@", key, self);
		
		return @(attributes.memoryPolicy == MTLPropertyMemoryPolicyWeak ? MTLModelEncodingBehaviorConditional : MTLModelEncodingBehaviorUnconditional);
	});
}

+ (NSDictionary *)allowedSecureCodingClassesByPropertyKey {
	NSDictionary *cachedClasses = objc_getAssociatedObject(self, MTLModelCachedAllowedClassesKey);
	if (cachedClasses != nil) return cachedClasses;

	NSDictionary *encodingBehaviors = self.encodingBehaviorsByPropertyKey;
	NSDictionary *allowedClasses = MTLCopyPropertyKeyMapUsingBlock(self, ^id(NSString *key, BOOL *__unused stop) {
		if ([encodingBehaviors[key] unsignedIntegerValue] == MTLModelEncodingBehaviorExcluded) {
			return nil;
		}

		MTLPropertyAttributes *attributes = [MTLPropertyAttributes propertyNamed:key class:self];
		NSAssert(attributes != nil, @"Could not find property \"%@\" on %@", key, self);

		if (attributes.type[0] != *(@encode(id)) && attributes.type[0] != *(@encode(Class))) {
			// If the property is not of object or class type, assume that it's
			// a primitive which would be boxed into an NSValue.
			return @[ NSValue.class ];
		} else if (attributes.objectClass != Nil) {
			// Omit this property from the dictionary if its class isn't known.
			return @[ attributes.objectClass ];
		}
		return nil;
	});

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedAllowedClassesKey, allowedClasses, OBJC_ASSOCIATION_COPY);

	return allowedClasses;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
	NSParameterAssert(key != nil);
	NSParameterAssert(coder != nil);

	SEL selector = MTLSelectorWithKeyPattern("decode", key, "WithCoder:modelVersion:");
	if ([self respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
		invocation.target = self;
		invocation.selector = selector;
		[invocation setArgument:&coder atIndex:2];
		[invocation setArgument:&modelVersion atIndex:3];
		[invocation invoke];

		__unsafe_unretained id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}

	@try {
		if (coder.requiresSecureCoding) {
			NSArray *allowedClasses = self.class.allowedSecureCodingClassesByPropertyKey[key];
			NSAssert(allowedClasses != nil, @"No allowed classes specified for securely decoding key \"%@\" on %@", key, self.class);
			
			return [coder decodeObjectOfClasses:[NSSet setWithArray:allowedClasses] forKey:key];
		} else {
			return [coder decodeObjectForKey:key];
		}
	} @catch (NSException *ex) {
		NSLog(@"*** Caught exception decoding value for key \"%@\" on class %@: %@", key, self.class, ex);
		@throw ex;
	}
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
	BOOL requiresSecureCoding = coder.requiresSecureCoding;
	NSNumber *version = nil;
	if (requiresSecureCoding) {
		version = [coder decodeObjectOfClass:NSNumber.class forKey:MTLModelVersionKey];
	} else {
		version = [coder decodeObjectForKey:MTLModelVersionKey];
	}
	
	if (version == nil) {
		NSLog(@"Warning: decoding an archive of %@ without a version, assuming 0", self.class);
	} else if (version.unsignedIntegerValue > self.class.modelVersion) {
		// Don't try to decode newer versions.
		return nil;
	}

	if (requiresSecureCoding) {
		verifyAllowedClassesByPropertyKey(self.class);
	}
	
	NSDictionary *dictionaryValue = MTLCopyPropertyKeyMapUsingBlock(self.class, ^(NSString *key, BOOL *__unused stop) {
		return [self decodeValueForKey:key withCoder:coder modelVersion:version.unsignedIntegerValue];
	});

	NSError *error = nil;
	self = [self initWithDictionary:dictionaryValue error:&error];
	if (self == nil) NSLog(@"*** Could not unarchive %@: %@", self.class, error);

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	if (coder.requiresSecureCoding) { verifyAllowedClassesByPropertyKey(self.class); }

	[coder encodeObject:@(self.class.modelVersion) forKey:MTLModelVersionKey];

	NSDictionary *encodingBehaviors = self.class.encodingBehaviorsByPropertyKey;
	[self.dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *__unused stop) {
		@try {
			// Skip nil values.
			if ([value isEqual:NSNull.null]) return;
			
			switch ([encodingBehaviors[key] unsignedIntegerValue]) {
					// This will also match a nil behavior.
				case MTLModelEncodingBehaviorExcluded:
					break;
					
				case MTLModelEncodingBehaviorUnconditional:
					[coder encodeObject:value forKey:key];
					break;
					
				case MTLModelEncodingBehaviorConditional:
					[coder encodeConditionalObject:value forKey:key];
					break;
					
				default:
					NSAssert(NO, @"Unrecognized encoding behavior %@ on class %@ for key \"%@\"", self.class, encodingBehaviors[key], key);
			}
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception encoding value for key \"%@\" on class %@: %@", key, self.class, ex);
			@throw ex;
		}
	}];
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
	// Disable secure coding support by default, so subclasses are forced to
	// opt-in by conforming to the protocol and overriding this method.
	//
	// We only implement this method because XPC complains if a subclass tries
	// to implement it but does not override -initWithCoder:. See
	// https://github.com/github/Mantle/issues/74.
	return NO;
}

@end
