//
//  NSDictionary+MTLMappingAdditions.m
//  Mantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel.h"

#import "NSDictionary+MTLMappingAdditions.h"

@implementation NSDictionary (MTLMappingAdditions)

+ (NSDictionary *)mtl_identityPropertyMapWithModel:(Class)class {
	NSCParameterAssert([class isSubclassOfClass:MTLModel.class]);

	NSArray *propertyKeys = [class propertyKeys].allObjects;

	return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

+ (NSDictionary *)mtl_propertyKeyMapWithModel:(Class <MTLModel>)class usingBlock:(id(^)(NSString *propertyName, BOOL *stop))block {
	NSParameterAssert(block);

	NSMutableDictionary *result = nil;
	NSSet *propertyKeys = [class propertyKeys];

	id sharedKeySet = nil;
	if ([(id)class respondsToSelector:@selector(sharedPropertyKeySet)]) {
		sharedKeySet = [class sharedPropertyKeySet];
	}

	if (sharedKeySet) {
		result = [NSMutableDictionary dictionaryWithSharedKeySet:sharedKeySet];
	} else {
		result = [NSMutableDictionary dictionaryWithCapacity:propertyKeys.count];
	}

	for (NSString *key in propertyKeys) {
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

@end
