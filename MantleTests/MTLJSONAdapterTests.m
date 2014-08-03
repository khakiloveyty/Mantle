//
//  MTLJSONAdapterTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"
#import "MTLTestJSONAdapter.h"

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
}

- (void)testSerializeSubclassFilterKeys
{
	values = @{
		@"username": @"foo",
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null }
	};

	MTLTestJSONAdapter *adapter = [[MTLTestJSONAdapter alloc] initWithModelClass:MTLTestModel.class];

	NSError *error;
	MTLTestModel *model = [adapter modelFromJSONDictionary:values error:&error];
	XCTAssertNotNil(model);
	XCTAssertNil(error);

	NSDictionary *complete = [adapter JSONDictionaryFromModel:model error:&error];

	XCTAssertEqualObjects(complete, values);
	XCTAssertNil(error);

	adapter.ignoredPropertyKeys = [NSSet setWithObjects:@"count", @"nestedName", nil];

	NSDictionary *partial = [adapter JSONDictionaryFromModel:model error:&error];

	XCTAssertEqualObjects(partial, @{ @"username": @"foo" });
	XCTAssertNil(error);
}

- (void)testDeserializeIdProperty
{
	values = @{
		@"anyObject": @"Not an NSValue"
	};

	NSError *error = nil;
	MTLIDModel *model = [MTLJSONAdapter modelOfClass:MTLIDModel.class fromJSONDictionary:values error:&error];
	XCTAssertNotNil(model);
	XCTAssertEqualObjects(model.anyObject, @"Not an NSValue");
	
	XCTAssertNil(error);
}

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
}

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
}

- (void)testSerializeCluster
{
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModelClass:MTLClassClusterModel.class];

	MTLChocolateClassClusterModel *chocolate = [MTLChocolateClassClusterModel modelWithDictionary:@{
		@"bitterness": @100
	} error:NULL];

	NSError *error;
	NSDictionary *chocolateValues = [adapter JSONDictionaryFromModel:chocolate error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(chocolateValues, (@{
		@"flavor": @"chocolate",
		@"chocolate_bitterness": @"100"
	}));

	MTLStrawberryClassClusterModel *strawberry = [MTLStrawberryClassClusterModel modelWithDictionary:@{
		@"freshness": @20
	} error:NULL];

	NSDictionary *strawberryValues = [adapter JSONDictionaryFromModel:strawberry error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(strawberryValues, (@{
		@"flavor": @"strawberry",
		@"strawberry_freshness": @20
	}));
}

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

- (void)testDeserializeValidate
{
	NSError *error = nil;
	MTLValidationModel *model = [MTLJSONAdapter modelOfClass:MTLValidationModel.class fromJSONDictionary:@{} error:&error];

	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTestModelErrorDomain);
	XCTAssertEqual(error.code, MTLTestModelNameMissing);
}

- (void)testDeserializeMultipleModels
{
	NSDictionary *value1 = @{
		@"username": @"foo"
	};

	NSDictionary *value2 = @{
		@"username": @"bar"
	};

	NSArray *JSONModels = @[ value1, value2 ];

	NSError *error;

	NSArray *mantleModels = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];

	XCTAssertNil(error);
	XCTAssertNotNil(mantleModels);
	XCTAssertEqual(mantleModels.count, (NSUInteger)2);
	XCTAssertEqualObjects([mantleModels[0] name], @"foo");
	XCTAssertEqualObjects([mantleModels[1] name], @"bar");

	NSArray *expected = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];
	NSArray *models = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:NULL];

	XCTAssertEqualObjects(models, expected, @"should not be affected by a NULL error parameter");
}

- (void)testDeserializeArrayFail
{
	NSDictionary *value1 = @{
		@"username": @"foo",
		@"count": @"1",
	};

	NSDictionary *value2 = @{
		@"count": @[ @"This won't parse" ],
	};

	NSArray *JSONModels = @[ value1, value2 ];

	NSError *error = nil;
	NSArray *mantleModels = [MTLJSONAdapter modelsOfClass:MTLSubstitutingTestModel.class fromJSONArray:JSONModels error:&error];
	
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLJSONAdapterErrorDomain);
	XCTAssertEqual(error.code, MTLJSONAdapterErrorNoClassFound);
	XCTAssertNil(mantleModels);
}

- (void)testDeserializeArray
{
	MTLTestModel *model1 = [[MTLTestModel alloc] init];
	model1.name = @"foo";

	MTLTestModel *model2 = [[MTLTestModel alloc] init];
	model2.name = @"bar";

	NSError *error;
	NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:@[ model1, model2 ] error:&error];

	XCTAssertNil(error);
	XCTAssertNotNil(JSONArray);
	XCTAssertEqual(JSONArray.count, (NSUInteger)2);
	XCTAssertEqualObjects(JSONArray[0][@"username"], @"foo");
	XCTAssertEqualObjects(JSONArray[1][@"username"], @"bar");
}

@end
