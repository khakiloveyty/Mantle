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

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testReturnMapping
{
	NSDictionary *mapping = @{
		@"name": @"name",
		@"count": @"count",
		@"nestedName": @"nestedName",
		@"weakModel": @"weakModel"
	};

	XCTAssertEqualObjects([NSDictionary mtl_identityPropertyMapWithModel:MTLTestModel.class], mapping, @"Should return a mapping");;
}

@end
