//
//  MTLValueTransformerTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

@interface MTLValueTransformerTests : XCTestCase
@end

@implementation MTLValueTransformerTests

- (void)testForwardTransformer
{
	MTLValueTransformer *transformer = [MTLValueTransformer transformerUsingForwardBlock:^(NSString *str, BOOL *success, NSError **error) {
		return [str stringByAppendingString:@"bar"];
	}];

	XCTAssertNotNil(transformer);
	XCTAssertFalse([transformer.class allowsReverseTransformation]);

	XCTAssertEqualObjects([transformer transformedValue:@"foo"], @"foobar");
	XCTAssertEqualObjects([transformer transformedValue:@"bar"], @"barbar");
}

- (void)testReversibleTransformer
{
	MTLValueTransformer *transformer = [MTLValueTransformer transformerUsingReversibleBlock:^(NSString *str, BOOL *success, NSError **error) {
		return [str stringByAppendingString:@"bar"];
	}];

	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);

	XCTAssertEqualObjects([transformer transformedValue:@"foo"], @"foobar");
	XCTAssertEqualObjects([transformer reverseTransformedValue:@"foo"], @"foobar");
}

- (void)testReversibleTwoWayTransformer
{
	MTLValueTransformer *transformer = [MTLValueTransformer
		transformerUsingForwardBlock:^(NSString *str, BOOL *success, NSError **error) {
			return [str stringByAppendingString:@"bar"];
		}
		reverseBlock:^(NSString *str, BOOL *success, NSError **error) {
			return [str substringToIndex:str.length - 3];
		}];

	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);

	XCTAssertEqualObjects([transformer transformedValue:@"foo"], @"foobar");
	XCTAssertEqualObjects([transformer reverseTransformedValue:@"foobar"], @"foo");
}

@end
