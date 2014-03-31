//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"
#import "MTLModel.h"
#import "MTLReflection.h"
#import "MTLPropertyAttributes.h"
#import <objc/runtime.h>

static const MTLPropertyStorage MTLPropertyStorageInvalid = NSNotFound;

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all permanent
// property keys.
static void *MTLModelCachedPermanentPropertyKeysKey = &MTLModelCachedPermanentPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all permanent
// property keys.
static void *MTLModelCachedPropertyKeysSharedKeySetKey = &MTLModelCachedPropertyKeysSharedKeySetKey;

// Validates a value for an object and sets it if necessary.
//
// obj         - The object for which the value is being validated. This value
//               must not be nil.
// key         - The name of one of `obj`s properties. This value must not be
//               nil.
// value       - The new value for the property identified by `key`.
// forceUpdate - If set to `YES`, the value is being updated even if validating
//               it did not change it.
// error       - If not NULL, this may be set to any error that occurs during
//               validation
//
// Returns YES if `value` could be validated and set, or NO if an error
// occurred.
static BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error) {
	// Mark this as being autoreleased, because validateValue may return
	// a new object to be stored in this variable (and we don't want ARC to
	// double-free or leak the old or new values).
	__autoreleasing id validatedValue = value;

	@try {
		if (![obj validateValue:&validatedValue forKey:key error:error]) return NO;

		if (forceUpdate || value != validatedValue) {
			[obj setValue:validatedValue forKey:key];
		}

		return YES;
	} @catch (NSException *ex) {
		NSLog(@"*** Caught exception setting key \"%@\" : %@", key, ex);

		// Fail fast in Debug builds.
		#if DEBUG
		@throw ex;
		#else
		if (error != NULL) {
			*error = [NSError mtl_modelErrorWithException:ex];
		}

		return NO;
		#endif
	}
}

@interface MTLModel ()

// Inspects all properties of returned by +propertyKeys using
// +storageBehaviorForPropertyWithKey and caches the results.
+ (void)generateAndCachePropertyKeys;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStoragePermanent.
+ (NSSet *)permanentPropertyKeys;

@end

@implementation MTLModel

#pragma mark Lifecycle

+ (void)generateAndCachePropertyKeys {
	NSMutableSet *transitoryKeys = [NSMutableSet set];
	NSMutableSet *permanentKeys = [NSMutableSet set];

	SEL selector = @selector(storageBehaviorForPropertyWithKey:);
	IMP myIMP = method_getImplementation(class_getClassMethod(self, selector));
	IMP theirIMP = method_getImplementation(class_getClassMethod(MTLModel.class, selector));
	BOOL implements = (myIMP != theirIMP);

	__block MTLPropertyAttributes *attributes = nil;
	[MTLPropertyAttributes enumeratePropertyNamesOfClass:self untilClass:MTLModel.class usingBlock:^(NSString *propertyKey) {
		MTLPropertyStorage storage = MTLPropertyStorageInvalid;

		if (implements) {
			storage = [self storageBehaviorForPropertyWithKey:propertyKey];
		}

		if (storage == MTLPropertyStorageInvalid) {
			MTLPropertyAttributes *thisAttr = [MTLPropertyAttributes propertyNamed:propertyKey class:self reusingAttributes:&attributes];
			storage = [self defaultStorageBehaviorForProperty:thisAttr];
		}

		switch (storage) {
			case MTLPropertyStorageNone:
				break;

			case MTLPropertyStorageTransitory:
				[transitoryKeys addObject:propertyKey];
				break;

			case MTLPropertyStoragePermanent:
				[permanentKeys addObject:propertyKey];
				break;
		}
	}];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey, permanentKeys, OBJC_ASSOCIATION_COPY);

	[permanentKeys unionSet:transitoryKeys];

	objc_setAssociatedObject(self, MTLModelCachedPropertyKeysKey, permanentKeys, OBJC_ASSOCIATION_COPY);
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	return [[self alloc] initWithDictionary:dictionary error:error];
}

- (instancetype)init {
	// Nothing special by default, but we have a declaration in the header.
	return [super init];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	self = [self init];
	if (self == nil) return nil;

	for (NSString *key in dictionary) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];

		if ([value isEqual:NSNull.null]) value = nil;

		BOOL success = MTLValidateAndSetValue(self, key, value, YES, error);
		if (!success) return nil;
	}

	return self;
}

#pragma mark Reflection

+ (NSSet *)propertyKeys {
	NSSet *propertyKeys = objc_getAssociatedObject(self, MTLModelCachedPropertyKeysKey);

	if (propertyKeys == nil) {
		[self generateAndCachePropertyKeys];
		propertyKeys = objc_getAssociatedObject(self, MTLModelCachedPropertyKeysKey);
	}

	return propertyKeys;
}

+ (NSSet *)permanentPropertyKeys {
	NSSet *permanentPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey);

	if (permanentPropertyKeys == nil) {
		[self generateAndCachePropertyKeys];
		permanentPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey);
	}

	return permanentPropertyKeys;
}

+ (id)sharedPropertyKeySet {
	id sharedPropertyKeySet = objc_getAssociatedObject(self, MTLModelCachedPropertyKeysSharedKeySetKey);
	if (sharedPropertyKeySet != nil) return sharedPropertyKeySet;

	sharedPropertyKeySet = [NSMutableDictionary sharedKeySetForKeys:self.propertyKeys.allObjects];

	objc_setAssociatedObject(self, MTLModelCachedPropertyKeysSharedKeySetKey, sharedPropertyKeySet, OBJC_ASSOCIATION_RETAIN);

	return sharedPropertyKeySet;

}

- (NSDictionary *)dictionaryValue {
	NSMutableDictionary *dictionaryValue = [NSMutableDictionary dictionaryWithSharedKeySet:self.class.sharedPropertyKeySet];

	for (NSString *key in self.class.propertyKeys) {
		dictionaryValue[key] = [self valueForKey:key] ?: NSNull.null;
	}

	return [dictionaryValue copy];
}

+ (MTLPropertyStorage)defaultStorageBehaviorForProperty:(MTLPropertyAttributes *)attributes {
	if (attributes == nil) return MTLPropertyStorageNone;

	if (attributes.readonly && attributes.ivar == NULL) {
		return MTLPropertyStorageNone;
	}

	return MTLPropertyStoragePermanent;
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	return MTLPropertyStorageInvalid;
}

#pragma mark Merging

- (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLModel> *)model {
	NSParameterAssert(key != nil);

	SEL selector = MTLSelectorWithKeyPattern("merge", key, "FromModel:");
	if (![self respondsToSelector:selector]) {
		if (model != nil) {
			[self setValue:[model valueForKey:key] forKey:key];
		}

		return;
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;

	[invocation setArgument:&model atIndex:2];
	[invocation invoke];
}

- (void)mergeValuesForKeysFromModel:(id<MTLModel>)model {
	for (NSString *key in self.class.propertyKeys) {
		[self mergeValueForKey:key fromModel:model];
	}
}

#pragma mark Validation

- (BOOL)validate:(NSError **)error {
	for (NSString *key in self.class.propertyKeys) {
		id value = [self valueForKey:key];

		BOOL success = MTLValidateAndSetValue(self, key, value, NO, error);
		if (!success) return NO;
	}

	return YES;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithDictionary:self.dictionaryValue error:NULL];
}

#pragma mark NSObject

- (NSString *)description {
	NSDictionary *permanentProperties = [self dictionaryWithValuesForKeys:self.class.permanentPropertyKeys.allObjects];

	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, permanentProperties];
}

- (NSUInteger)hash {
	NSUInteger value = 0;

	for (NSString *key in self.class.permanentPropertyKeys) {
		value ^= [[self valueForKey:key] hash];
	}

	return value;
}

- (BOOL)isEqual:(MTLModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	for (NSString *key in self.class.permanentPropertyKeys) {
		id selfValue = [self valueForKey:key];
		id modelValue = [model valueForKey:key];

		BOOL valuesEqual = ((selfValue == nil && modelValue == nil) || [selfValue isEqual:modelValue]);
		if (!valuesEqual) return NO;
	}

	return YES;
}

@end
