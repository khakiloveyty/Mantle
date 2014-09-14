//
//  MTLComparisonAdditionsTests.m
//  Mantle
//
//  Created by Josh Vera on 10/26/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

@import XCTest;
@import Mantle;

@interface MTLComparisonAdditionsTests : XCTestCase
@end

@implementation MTLComparisonAdditionsTests {
	id obj1, obj2;
}

- (void)setUp
{
    [super setUp];

	obj1 = @"Test1";
	obj2 = @"Test2";
}

- (void)testNilObjects
{
	XCTAssertTrue(MTLEqualObjects(nil, nil), @"Returns true when given two values of nil");
}

- (void)testEqualObjects
{
	XCTAssertTrue(MTLEqualObjects(obj1, obj1), @"Returns true when given two equal objects");
}

- (void)testInequalObjects
{
	XCTAssertFalse(MTLEqualObjects(obj1, obj2), @"Returns false when given two inequal objects");
}

- (void)testObjectAndNil
{
	XCTAssertFalse(MTLEqualObjects(obj1, nil), @"Returns false when given an object and nil");
}

- (void)testSymmetric
{
	XCTAssertEqual(MTLEqualObjects(obj2, obj1), MTLEqualObjects(obj1, obj2), @"Returns the same value when given symmetric arguments");
}

- (void)testMutableObjects
{
	id mutableObj1 = [obj1 mutableCopy];
	id mutableObj2 = [obj1 mutableCopy];

	XCTAssertTrue(MTLEqualObjects(mutableObj1, mutableObj2), @"Returns true when given two equal but not identical objects");
}

@end
