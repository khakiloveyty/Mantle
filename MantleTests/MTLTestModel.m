//
//  MTLTestModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

NSString * const MTLTestModelErrorDomain = @"MTLTestModelErrorDomain";
const NSInteger MTLTestModelNameTooLong = 1;
const NSInteger MTLTestModelNameMissing = 2;

static NSUInteger modelVersion = 1;

@implementation MTLEmptyTestModel
@end

@implementation MTLTestModel

#pragma mark Properties

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if ([*name length] < 10) return YES;
	if (error != NULL) {
		*error = [NSError errorWithDomain:MTLTestModelErrorDomain code:MTLTestModelNameTooLong userInfo:nil];
	}

	return NO;
}

- (NSString *)dynamicName {
	return self.name;
}

#pragma mark Versioning

+ (void)setModelVersion:(NSUInteger)version {
	modelVersion = version;
}

+ (NSUInteger)modelVersion {
	return modelVersion;
}

#pragma mark Lifecycle

- (instancetype)init {
	self = [super init];
	if (self == nil) return nil;

	self.count = 1;
	return self;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];

	if (modelVersion == 0) {
		[coder encodeObject:self.name forKey:@"mtl_name"];
	}
}

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *dict = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    dict[@"nestedName"] = @(MTLModelEncodingBehaviorExcluded);
    return dict;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)fromVersion {
	NSParameterAssert(key != nil);
	NSParameterAssert(coder != nil);

	if ([key isEqual:@"name"] && fromVersion == 0) {
		return [@"M: " stringByAppendingString:[coder decodeObjectForKey:@"mtl_name"]];
	}

	return [super decodeValueForKey:key withCoder:coder modelVersion:fromVersion];
}

#pragma mark Property Storage Behavior

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	if ([propertyKey isEqual:@"weakModel"]) {
		return MTLPropertyStorageTransitory;
	} else {
		return [super storageBehaviorForPropertyWithKey:propertyKey];
	}
}

#pragma mark Merging

- (void)mergeCountFromModel:(MTLTestModel *)model {
	self.count += model.count;
}

@end

@implementation MTLSubclassTestModel
@end

@implementation MTLValidationModel

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	if (*name != nil) return YES;
	if (error != NULL) {
		*error = [NSError errorWithDomain:MTLTestModelErrorDomain code:MTLTestModelNameMissing userInfo:nil];
	}

	return NO;
}

@end

@implementation MTLSelfValidatingModel

- (BOOL)validateName:(NSString **)name error:(__unused NSError **)error {
	if (*name != nil) return YES;

	*name = @"foobar";

	return YES;
}

@end

@implementation MTLStorageBehaviorModel

- (id)notIvarBacked {
	return self;
}

@end
