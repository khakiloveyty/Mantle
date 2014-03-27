//
//  MTLJSONAdapterTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

@interface MTLJSONAdapterTests : XCTestCase
@end

@implementation MTLJSONAdapterTests {
	NSDictionary *values;
}

- (void)setUp
{
    [super setUp];

    values = nil;
}

- (void)testDeserialize
{
	values = @{
		@"username": NSNull.null,
		@"count": @"5",
	};

	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModelClass:MTLTestModel.class];
	XCTAssertNotNil(adapter);
	XCTAssertNil(error);

	MTLTestModel *model = (id)[adapter modelFromJSONDictionary:values error:&error];
	XCTAssertNil(error);

	XCTAssertNotNil(model);
	XCTAssertNil(model.name);
	XCTAssertEqual(model.count, (NSUInteger)5);
	
	NSDictionary *JSONDictionary = @{
		@"username": NSNull.null,
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	XCTAssertEqualObjects([adapter JSONDictionaryFromModel:model error:&error], JSONDictionary);
	XCTAssertNil(error);
}

- (void)testDeserializeNestedKeypaths
{
	values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertNotNil(model);
	XCTAssertNil(error);

	XCTAssertEqualObjects(model.name, @"foo");
	XCTAssertEqual(model.count, (NSUInteger)0);
	XCTAssertEqualObjects(model.nestedName, @"bar");

	XCTAssertEqualObjects([MTLJSONAdapter JSONDictionaryFromModel:model error:&error], values);
	XCTAssertNil(error);
}

- (void)testDeserializeMultipleKeypaths
{
	values = @{
		@"location": @20,
		@"length": @12,
		@"nested": @{
			@"location": @12,
			@"length": @34
		}
	};

	NSError *error = nil;
	MTLMultiKeypathModel *model = [MTLJSONAdapter modelOfClass:MTLMultiKeypathModel.class fromJSONDictionary:values error:&error];
	XCTAssertNotNil(model);
	XCTAssertNil(error);

	XCTAssertTrue(NSEqualRanges(model.range, NSMakeRange(20, 12)));
	XCTAssertTrue(NSEqualRanges(model.nestedRange, NSMakeRange(12, 34)));

	XCTAssertEqualObjects([MTLJSONAdapter JSONDictionaryFromModel:model error:&error], values);
	XCTAssertNil(error);
}

- (void)testDeserializeInvalidKeypath
{
	values = @{
		@"username": @"foo",
		@"nested": @"bar",
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLJSONAdapterErrorDomain);
	XCTAssertEqual(error.code, MTLJSONAdapterErrorInvalidJSONDictionary);
}

- (void)testDeserializeKeypathsAcrossArrays
{
	values = @{
		@"users": @[
			@{
				@"name": @"foo"
			},
			@{
				@"name": @"bar"
			},
			@{
				@"name": @"baz"
			}
		]
	};

	NSError *error = nil;
	MTLArrayTestModel *model = [MTLJSONAdapter modelOfClass:MTLArrayTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLJSONAdapterErrorDomain);
	XCTAssertEqual(error.code, MTLJSONAdapterErrorInvalidJSONDictionary);
}

- (void)testDeserializeNullDictionaryValue
{
	values = @{
		@"username": @"foo",
		@"nested": NSNull.null,
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(error);

	XCTAssertNotNil(model);
	XCTAssertEqualObjects(model.name, @"foo");
	XCTAssertEqual(model.count, (NSUInteger)0);
	XCTAssertNil(model.nestedName);
}

- (void)testDeserializeIgnoreUnrecognizedKeys
{
	values = @{
		@"foobar": @"foo",
		@"count": @"2",
		@"_": NSNull.null,
		@"username": @"buzz",
		@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(error);

	XCTAssertNotNil(model);
	XCTAssertEqualObjects(model.name, @"buzz");
	XCTAssertEqual(model.count, (NSUInteger)2);
	XCTAssertEqualObjects(model.nestedName, @"bar");
}

- (void)testDeserializeDictionaryValidation
{
	values = @{
		@"username": @"this is too long a name",
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTestModelErrorDomain);
	XCTAssertEqual(error.code, MTLTestModelNameTooLong);
}

- (void)testImplicitTransformURLs
{
	MTLURLModel *model = [[MTLURLModel alloc] init];

	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];

	XCTAssertEqualObjects(JSONDictionary[@"URL"], @"http://github.com");
	XCTAssertNil(error);
}

- (void)testImplicitTransformBOOLs
{
	MTLBoolModel *model = [[MTLBoolModel alloc] init];

	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];

	XCTAssertEqual(JSONDictionary[@"flag"], (__bridge id)kCFBooleanFalse);
	XCTAssertNil(error);
}

- (void)testImplicitTransformersNonProperties
{
	MTLNonPropertyModel *model = [[MTLNonPropertyModel alloc] init];

	NSError *error = nil;
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];

	XCTAssertEqualObjects(JSONDictionary[@"homepage"], model.homepage);
	XCTAssertNil(error);
}

- (void)testDeserializeTransformerFailure
{
	values = @{
		@"URL": @666,
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLURLModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTransformerErrorHandlingErrorDomain);
	XCTAssertEqual(error.code, MTLTransformerErrorHandlingErrorInvalidInput);
	XCTAssertEqualObjects(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey], @666);
}

- (void)testDeserializeTypeMismatch
{
	values = @{
		@"flag": @"Potentially"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLBoolModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTransformerErrorHandlingErrorDomain);
	XCTAssertEqual(error.code, MTLTransformerErrorHandlingErrorInvalidInput);
	XCTAssertEqualObjects(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey], @"Potentially");
};

- (void)testDeserializeIdProperty
{
	values = @{
		@"anyObject": @"Not an NSValue"
	};

	NSError *error = nil;
	MTLIDModel *model = [MTLJSONAdapter modelOfClass:MTLIDModel.class fromJSONDictionary:values error:&error];
	XCTAssertNil(error);

	XCTAssertNotNil(model);
	XCTAssertEqualObjects(model.anyObject, @"Not an NSValue");
};

- (void)testSerializeTransformerFail
{
	MTLURLModel *model = [[MTLURLModel alloc] init];

	[model setValue:@"totallyNotAnNSURL" forKey:@"URL"];

	NSError *error;
	NSDictionary *dictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
	XCTAssertNil(dictionary);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTransformerErrorHandlingErrorDomain);
	XCTAssertEqual(error.code, MTLTransformerErrorHandlingErrorInvalidInput);
	XCTAssertEqualObjects(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey], @"totallyNotAnNSURL");
};

- (void)testParseDifferentModel
{
	values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:values error:&error];
	XCTAssertTrue([model isKindOfClass:MTLTestModel.class]);
	XCTAssertNil(error);

	XCTAssertEqualObjects(model.name, @"foo");
	XCTAssertEqual(model.count, (NSUInteger)0);
	XCTAssertEqualObjects(model.nestedName, @"bar");

	XCTAssertEqualObjects([MTLJSONAdapter JSONDictionaryFromModel:model error:&error], values);
	XCTAssertNil(error);
};

- (void)testParseNonMantleModel
{
	values = @{
		@"name": @"foo",
	};

	NSError *error = nil;
	MTLConformingModel *model = [MTLJSONAdapter modelOfClass:MTLConformingModel.class fromJSONDictionary:values error:&error];
	XCTAssertTrue([model isKindOfClass:MTLConformingModel.class]);
	XCTAssertNil(error);

	XCTAssertEqualObjects(model.name, @"foo");
};

- (void)testDeserializeModelClassFail
{
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:@{} error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLJSONAdapterErrorDomain);
	XCTAssertEqual(error.code, MTLJSONAdapterErrorNoClassFound);
}

@end
