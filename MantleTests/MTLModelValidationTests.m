//
//  MTLModelValidationTests.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

@import Foundation;
@import XCTest;
@import Mantle;

#import "MTLTestModel.h"

@interface MTLModelValidationTests : XCTestCase
@end

@implementation MTLModelValidationTests

- (void)testFail
{
	MTLValidationModel *model = [[MTLValidationModel alloc] init];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	XCTAssertFalse(success);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTestModelErrorDomain);
	XCTAssertEqual(error.code, MTLTestModelNameMissing);
}

- (void)testSuccess
{
	MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:@{ @"name": @"valid" } error:NULL];
	
	NSError *error = nil;
	BOOL success = [model validate:&error];
	XCTAssertTrue(success);
	
	XCTAssertNil(error);
}

- (void)testApply
{
	MTLSelfValidatingModel *model = [[MTLSelfValidatingModel alloc] init];

	NSError *error = nil;
	BOOL success = [model validate:&error];
	XCTAssertNil(error);

	XCTAssertTrue(success);
	XCTAssertEqualObjects(model.name, @"foobar");
}

@end
