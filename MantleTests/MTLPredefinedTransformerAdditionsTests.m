//
//  MTLPredefinedTransformerAdditionsTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@import Foundation;
@import XCTest;
@import Mantle;

#import "MTLTestModel.h"

@interface MTLPredefinedTransformerAdditionsTests : XCTestCase {
	NSValueTransformer *transformer;
}

- (void)commonTestTransformerWithInvalidInput:(id)invalidTransformationInput invalidReverseInput:(id)invalidReverseTransformationInput;

@end

@implementation MTLPredefinedTransformerAdditionsTests

- (void)commonTestTransformerWithInvalidInput:(id)invalidTransformationInput invalidReverseInput:(id)invalidReverseTransformationInput
{
	XCTAssertTrue([transformer conformsToProtocol:@protocol(MTLTransformerErrorHandling)]);

	NSValueTransformer <MTLTransformerErrorHandling> *localTransformer = (id)transformer;

	NSError *error = nil;
	BOOL success = NO;

	XCTAssertNil([localTransformer transformedValue:invalidTransformationInput success:&success error:&error]);
	XCTAssertFalse(success);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTransformerErrorHandlingErrorDomain);
	XCTAssertEqual(error.code, MTLTransformerErrorHandlingErrorInvalidInput);
	XCTAssertEqualObjects(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey], invalidTransformationInput);

	if ([localTransformer.class allowsReverseTransformation]) {
		XCTAssertNil([localTransformer reverseTransformedValue:invalidReverseTransformationInput success:&success error:&error]);
		XCTAssertFalse(success);
		XCTAssertNotNil(error);
		XCTAssertEqualObjects(error.domain, MTLTransformerErrorHandlingErrorDomain);
		XCTAssertEqual(error.code, MTLTransformerErrorHandlingErrorInvalidInput);
		XCTAssertEqualObjects(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey], invalidReverseTransformationInput);
	}
}

@end

#pragma mark - Array mapping

@interface MTLArrayMappingTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLArrayMappingTransformerTests {
	NSArray *URLStrings;
	NSArray *URLs;
}

- (void)setUp
{
	[super setUp];
	
	URLStrings = @[
		@"https://github.com/",
		@"https://github.com/MantleFramework",
		@"http://apple.com"
	];

	URLs = @[
		[NSURL URLWithString:@"https://github.com/"],
		[NSURL URLWithString:@"https://github.com/MantleFramework"],
		[NSURL URLWithString:@"http://apple.com"]
	];
}

- (void)testWithReversibleTransformer
{
	NSValueTransformer *appliedTransformer = [MTLValueTransformer transformerUsingForwardBlock:^(NSString *str, BOOL *__unused success, __unused NSError **error) {
        return [NSURL URLWithString:str];
    } reverseBlock:^(NSURL *URL, BOOL *__unused success, __unused NSError **error) {
        return URL.absoluteString;
    }];
	transformer = [NSValueTransformer mtl_arrayMappingTransformerWithTransformer:appliedTransformer];
	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);

	XCTAssertEqualObjects([transformer transformedValue:URLStrings], URLs);
	XCTAssertEqualObjects([transformer reverseTransformedValue:URLs], URLStrings);

	[self commonTestTransformerWithInvalidInput:NSNull.null invalidReverseInput:NSNull.null];
}

- (void)testWithForwardTransformer
{
	MTLValueTransformer *appliedTransformer = [MTLValueTransformer transformerUsingForwardBlock:^(NSString *str, BOOL *__unused success, __unused NSError **error) {
		return [NSURL URLWithString:str];
	}];
	transformer = [NSValueTransformer mtl_arrayMappingTransformerWithTransformer:appliedTransformer];
	XCTAssertNotNil(transformer);
	XCTAssertFalse([transformer.class allowsReverseTransformation]);

	XCTAssertEqualObjects([transformer transformedValue:URLStrings], URLs);

	[self commonTestTransformerWithInvalidInput:NSNull.null invalidReverseInput:NSNull.null];
}

@end

#pragma mark - Value mapping

enum : NSInteger {
	MTLValueMappingTransformerEnumNegative = -1,
	MTLValueMappingTransformerEnumZero = 0,
	MTLValueMappingTransformerEnumPositive = 1,
	MTLValueMappingTransformerEnumDefault = 42,
} MTLValueMappingTransformerEnum;

static inline NSDictionary *MTLValueMappingTransformerMap(void) {
	return @{
		@"negative": @(MTLValueMappingTransformerEnumNegative),
		@[ @"zero" ]: @(MTLValueMappingTransformerEnumZero),
		@"positive": @(MTLValueMappingTransformerEnumPositive),
	};
}

@interface MTLValueMappingTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLValueMappingTransformerTests

- (void)setUp
{
	[super setUp];
	
	transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:MTLValueMappingTransformerMap() defaultValue:nil reverseDefaultValue:nil];
	
	XCTAssertNotNil(transformer);
}

- (void)testTransform
{
	XCTAssertEqualObjects([transformer transformedValue:@"negative"], @(MTLValueMappingTransformerEnumNegative));
	XCTAssertEqualObjects([transformer transformedValue:@[ @"zero" ]], @(MTLValueMappingTransformerEnumZero));
	XCTAssertEqualObjects([transformer transformedValue:@"positive"], @(MTLValueMappingTransformerEnumPositive));
}

- (void)testReverseTransform
{
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
	
	XCTAssertEqualObjects([transformer reverseTransformedValue:@(MTLValueMappingTransformerEnumNegative)], @"negative");
	XCTAssertEqualObjects([transformer reverseTransformedValue:@(MTLValueMappingTransformerEnumZero)], @[ @"zero" ]);
	XCTAssertEqualObjects([transformer reverseTransformedValue:@(MTLValueMappingTransformerEnumPositive)], @"positive");
}

@end

@interface MTLValueMappingDefaultTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLValueMappingDefaultTransformerTests

- (void)setUp
{
	[super setUp];
	
	transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:MTLValueMappingTransformerMap() defaultValue:@(MTLValueMappingTransformerEnumDefault) reverseDefaultValue:@"default"];

	XCTAssertNotNil(transformer);
}

- (void)testTransform
{
	XCTAssertEqualObjects([transformer transformedValue:@"unknown"], @(MTLValueMappingTransformerEnumDefault));
}

- (void)testReverseTransform
{
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
	
	XCTAssertEqualObjects([transformer reverseTransformedValue:@(MTLValueMappingTransformerEnumDefault)], @"default");
}

@end
