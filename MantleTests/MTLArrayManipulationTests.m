//
//  MTLArrayManipulationTests.m
//  Mantle
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@interface MTLArrayManipulationTests : XCTestCase

@end

@implementation MTLArrayManipulationTests {
	NSArray *array, *expected;
}

- (void)setUp {
	[super setUp];

	array = nil;
	expected = nil;
}

- (void)testArrayByRemovingObject
{
	array = @[ @1, @2, @3 ];
	expected = @[ @2, @3 ];
	XCTAssertEqualObjects([array mtl_arrayByRemovingObject:@1], expected, @"Should return a new array without the object");
	
	array = @[ @1, @2, @3, @1, @1 ];
	expected = @[ @2, @3 ];
	XCTAssertEqualObjects([array mtl_arrayByRemovingObject:@1], expected, @"Should return a new array without all occurrences of the object");
	
	array = @[ @1, @2, @3 ];
	XCTAssertEqualObjects([array mtl_arrayByRemovingObject:@42], array, @"Should return an equivalent array if it doesn't contain the object");
}

- (void)testArrayByRemovingFirstObject
{
	array = @[ @1, @2, @3 ];
	expected = @[ @2, @3 ];
	XCTAssertEqualObjects(array.mtl_arrayByRemovingFirstObject, expected, @"Should return the array without the first object");
	
	array = @[];
	XCTAssertEqualObjects(array.mtl_arrayByRemovingFirstObject, array, @"Should return the same array if it's empty");
}

- (void)testArrayByRemovingLastObject
{
	array = @[ @1, @2, @3 ];
	expected = @[ @1, @2 ];
	XCTAssertEqualObjects(array.mtl_arrayByRemovingLastObject, expected, @"Should return the array without the last object");
	
	array = @[];
	XCTAssertEqualObjects(array.mtl_arrayByRemovingLastObject, array, @"Should return the same array if it's empty");
}

@end
