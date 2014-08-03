//
//  MTLValueTransformerInversionAdditionsTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-18.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

@interface TestTransformer : NSValueTransformer
@end

@implementation TestTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return NSString.class;
}

- (id)transformedValue:(__unused id)value {
	return @"forward";
}

- (id)reverseTransformedValue:(__unused id)value {
	return @"reverse";
}

@end

@interface MTLValueTransformerInversionAdditionsTests : XCTestCase
@end

@implementation MTLValueTransformerInversionAdditionsTests {
	TestTransformer *transformer;
}

- (void)setUp
{
    [super setUp];

	transformer = [[TestTransformer alloc] init];
	XCTAssertNotNil(transformer);
}

- (void)testInvert
{
	NSValueTransformer *inverted = transformer.mtl_invertedTransformer;
	XCTAssertNotNil(inverted);

	XCTAssertEqualObjects([inverted transformedValue:nil], @"reverse");
	XCTAssertEqualObjects([inverted reverseTransformedValue:nil], @"forward");
}

- (void)testInvertInverted
{
	NSValueTransformer *inverted = transformer.mtl_invertedTransformer.mtl_invertedTransformer;
	XCTAssertNotNil(inverted);

	XCTAssertEqualObjects([inverted transformedValue:nil], @"forward");
	XCTAssertEqualObjects([inverted reverseTransformedValue:nil], @"reverse");
};

@end
