//
//  MTLDictionaryMappingTests.m
//  Mantle
//
//  Created by Robert Böhnke on 10/23/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

@interface MTLDictionaryMappingTests : XCTestCase

@end

@implementation MTLDictionaryMappingTests

- (void)testReturnsMapping {
	NSDictionary *mapping = @{
		@"name": @"name",
		@"count": @"count",
		@"nestedName": @"nestedName",
		@"weakModel": @"weakModel"
	};
	
	XCTAssertEqualObjects([NSDictionary mtl_identityPropertyMapWithModel:MTLTestModel.class], mapping, @"should return a mapping");
}

@end
