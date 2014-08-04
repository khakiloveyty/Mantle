//
//  NSDictionary+MTLMappingAdditions.m
//  Mantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSDictionary+MTLMappingAdditions.h"
#import "MTLReflection.h"

static void *MTLCachedPropertyKeysSharedKeySetKey = &MTLCachedPropertyKeysSharedKeySetKey;

@implementation NSDictionary (MTLMappingAdditions)

+ (NSDictionary *)mtl_identityPropertyMapWithModel:(Class <MTLModel>)cls {
	return MTLCopyPropertyKeyMapUsingBlock(cls, ^(NSString *propertyName, BOOL *__unused stop) {
		return propertyName;
	});
}

@end
