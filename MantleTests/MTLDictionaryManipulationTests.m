//
//  MTLDictionaryManipulationTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-24.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@import XCTest;
@import Mantle;

@interface MTLDictionaryManipulationTests : XCTestCase
@end

@implementation MTLDictionaryManipulationTests {
	NSDictionary *dict;
}

- (void)setUp
{
	[super setUp];

	dict = @{ @"foo": @"bar", @(5): NSNull.null };
}

- (void)testAddingToEmpty
{
	NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{}];
	XCTAssertEqualObjects(combined, dict, @"Should return the same dictionary when adding from an empty dictionary");
}

- (void)testAddingFromNil
{
	NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:nil];
	XCTAssertEqualObjects(combined, dict, @"Should return the same dictionary when adding from nil");
}

- (void)testAddingNewKeys
{
	NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{ @"buzz": @(10), @"baz": NSNull.null }];
	NSDictionary *expected = @{ @"foo": @"bar", @(5): NSNull.null, @"buzz": @(10), @"baz": NSNull.null };
	XCTAssertEqualObjects(combined, expected, @"Should add any new keys");
}

- (void)testAddingReplacingKeys
{
	NSDictionary *combined = [dict mtl_dictionaryByAddingEntriesFromDictionary:@{ @(5): @(10), @"buzz": @"baz" }];
	NSDictionary *expected = @{ @"foo": @"bar", @(5): @(10), @"buzz": @"baz" };
	XCTAssertEqualObjects(combined, expected, @"Should replace any existing keys");
}

- (void)testRemovingUnusedKeys
{
	NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:@[ @"hi"]];
	XCTAssertEqualObjects(removed, dict, @"Should return the same dictionary when removing keys that don't exist in the receiver");
}

- (void)testRemovingNilKeys
{
	NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:nil];
	XCTAssertEqualObjects(removed, dict, @"should return the same dictionary when given a nil array of keys");
}

- (void)testRemovingKeys
{
	NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:@[ @5 ]];
	NSDictionary *expected = @{ @"foo": @"bar" };
	XCTAssertEqualObjects(removed, expected, @"should remove all the entries for the given keys");
}

- (void)testRemovingAllKeys
{
	NSDictionary *removed = [dict mtl_dictionaryByRemovingValuesForKeys:dict.allKeys];
	NSDictionary *expected = @{};
	XCTAssertEqualObjects(removed, expected, @"should return an empty dictionary when it removes all its keys");
}

@end
