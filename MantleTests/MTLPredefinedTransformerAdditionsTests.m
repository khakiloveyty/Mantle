//
//  MTLPredefinedTransformerAdditionsTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

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

#pragma mark - URL

@interface MTLURLValueTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLURLValueTransformerTests

- (void)setUp
{
	[super setUp];

	transformer = [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];

	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
}

- (void)testTransform
{
	NSString *URLString = @"http://www.github.com/";
	XCTAssertEqualObjects([transformer transformedValue:URLString], [NSURL URLWithString:URLString]);
	XCTAssertEqualObjects([transformer reverseTransformedValue:[NSURL URLWithString:URLString]], URLString);
}

- (void)testTransformNil
{
	XCTAssertNil([transformer transformedValue:nil]);
	XCTAssertNil([transformer reverseTransformedValue:nil]);
}

- (void)testTransformFail
{
	[self commonTestTransformerWithInvalidInput:@"not a valid URL" invalidReverseInput:NSNull.null];
}

@end

#pragma mark - Number

@interface MTLNumberValueTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLNumberValueTransformerTests

- (void)setUp
{
	[super setUp];

	transformer = [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];

	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
}

- (void)testTransform
{
	// Back these NSNumbers with ints, rather than booleans,
	// to ensure that the value transformers are actually transforming.
	NSNumber *booleanYES = @(1);
	NSNumber *booleanNO = @(0);

	XCTAssertEqualObjects([transformer transformedValue:booleanYES], @YES);
	XCTAssertEqual([transformer transformedValue:booleanYES], (__bridge id)kCFBooleanTrue);

	XCTAssertEqualObjects([transformer reverseTransformedValue:booleanYES], @YES);
	XCTAssertEqual([transformer reverseTransformedValue:booleanYES], (__bridge id)kCFBooleanTrue);

	XCTAssertEqualObjects([transformer transformedValue:booleanNO], @NO);
	XCTAssertEqual([transformer transformedValue:booleanNO], (__bridge id)kCFBooleanFalse);

	XCTAssertEqualObjects([transformer reverseTransformedValue:booleanNO], @NO);
	XCTAssertEqual([transformer reverseTransformedValue:booleanNO], (__bridge id)kCFBooleanFalse);
}

- (void)testTransformNil
{
	XCTAssertNil([transformer transformedValue:nil]);
	XCTAssertNil([transformer reverseTransformedValue:nil]);
}

- (void)testTransformFail
{
	[self commonTestTransformerWithInvalidInput:NSNull.null invalidReverseInput:NSNull.null];
}

@end

#pragma mark - Dictionary

@interface MTLDictionaryValueTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLDictionaryValueTransformerTests {
	MTLTestModel *model;
	NSDictionary *JSONDictionary;
}

- (void)setUp
{
	[super setUp];

	model = [[MTLTestModel alloc] init];
	JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:NULL];

	transformer = [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:MTLTestModel.class];

	XCTAssertNotNil(transformer);
}

- (void)testTransform
{
	XCTAssertEqualObjects([transformer transformedValue:JSONDictionary], model);
}

- (void)testReverseTransform
{
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
	XCTAssertEqualObjects([transformer reverseTransformedValue:model], JSONDictionary);
};

- (void)testTransformFail
{
	[self commonTestTransformerWithInvalidInput:NSNull.null invalidReverseInput:NSNull.null];
}

@end

#pragma mark - External array

@interface MTLExternalArrayValueTransformerTests : MTLPredefinedTransformerAdditionsTests
@end

@implementation MTLExternalArrayValueTransformerTests {
	NSArray *models;
	NSArray *JSONDictionaries;
}

- (void)setUp
{
	[super setUp];

	NSMutableArray *uniqueModels = [NSMutableArray array];
	NSMutableArray *mutableDictionaries = [NSMutableArray array];

	for (NSUInteger i = 0; i < 10; i++) {
		MTLTestModel *model = [[MTLTestModel alloc] init];
		model.count = i;

		[uniqueModels addObject:model];

		NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:model error:NULL];
		XCTAssertNotNil(dict);

		[mutableDictionaries addObject:dict];
	}

	uniqueModels[2] = NSNull.null;
	mutableDictionaries[2] = NSNull.null;

	models = [uniqueModels copy];
	JSONDictionaries = [mutableDictionaries copy];

	transformer = [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:MTLTestModel.class];
	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
}

- (void)testTransform
{
	XCTAssertEqualObjects([transformer transformedValue:JSONDictionaries], models);
}

- (void)testReverseTransform
{
	XCTAssertTrue([transformer.class allowsReverseTransformation]);
	XCTAssertEqualObjects([transformer reverseTransformedValue:models], JSONDictionaries);
};

- (void)testTransformFail
{
	[self commonTestTransformerWithInvalidInput:NSNull.null invalidReverseInput:NSNull.null];
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
	NSValueTransformer *appliedTransformer = [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
	transformer = [NSValueTransformer mtl_arrayMappingTransformerWithTransformer:appliedTransformer];
	XCTAssertNotNil(transformer);
	XCTAssertTrue([transformer.class allowsReverseTransformation]);

	XCTAssertEqualObjects([transformer transformedValue:URLStrings], URLs);
	XCTAssertEqualObjects([transformer reverseTransformedValue:URLs], URLStrings);

	[self commonTestTransformerWithInvalidInput:NSNull.null invalidReverseInput:NSNull.null];
}

- (void)testWithForwardTransformer
{
	NSValueTransformer *appliedTransformer = [MTLValueTransformer transformerUsingForwardBlock:^(NSString *str, BOOL *success, NSError **error) {
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
	
	transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:MTLValueMappingTransformerMap()];
	
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
