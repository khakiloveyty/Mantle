//
//  MTLModelTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

@interface MTLModelTests : XCTestCase
@end

@implementation MTLModelTests

- (void)testNoProperties
{
	XCTAssertEqualObjects(MTLEmptyTestModel.propertyKeys, [NSSet set], @"Should not loop infinitely in +propertyKeys without any properties");
}

- (void)testDynamicReadonlyProperties
{
	NSSet *expectedKeys = [NSSet setWithObjects:@"name", @"count", @"nestedName", @"weakModel", nil];
	XCTAssertEqualObjects(MTLTestModel.propertyKeys, expectedKeys, @"Should not include dynamic readonly properties in +propertyKeys");
}

- (void)testDefaultValues
{
	MTLTestModel *model = [[MTLTestModel alloc] init];
	XCTAssertNotNil(model);

	XCTAssertNil(model.name);
	XCTAssertEqual(model.count, (NSUInteger)1);

	NSDictionary *expectedValues = @{
		@"name": NSNull.null,
		@"count": @(1),
		@"nestedName": NSNull.null,
		@"weakModel": NSNull.null,
	};

	XCTAssertEqualObjects(model.dictionaryValue, expectedValues);
	XCTAssertEqualObjects([model dictionaryWithValuesForKeys:expectedValues.allKeys], expectedValues);
}

- (void)testDefaultValuesNilDictionary
{
	NSError *error = nil;
	MTLTestModel *dictionaryModel = [[MTLTestModel alloc] initWithDictionary:nil error:&error];
	XCTAssertNotNil(dictionaryModel);
	XCTAssertNil(error);

	MTLTestModel *defaultModel = [[MTLTestModel alloc] init];
	XCTAssertEqualObjects(dictionaryModel, defaultModel);
}

- (void)testValidationFailure
{
	NSError *error = nil;
	MTLTestModel *model = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"this is too long a name" } error:&error];
	XCTAssertNil(model);

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLTestModelErrorDomain);
	XCTAssertEqual(error.code, MTLTestModelNameTooLong);
}

- (void)testMerge
{
	MTLTestModel *target = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"foo", @"count": @(5) } error:NULL];
	XCTAssertNotNil(target);

	MTLTestModel *source = [[MTLTestModel alloc] initWithDictionary:@{ @"name": @"bar", @"count": @(3) } error:NULL];
	XCTAssertNotNil(source);

	[target mergeValuesForKeysFromModel:source];

	XCTAssertEqualObjects(target.name, @"bar");
	XCTAssertEqual(target.count, (NSUInteger)8);
}

- (void)testPrimitivePermanent
{
	XCTAssertEqual([MTLStorageBehaviorModel storageBehaviorForPropertyWithKey:@"primitive"], MTLPropertyStoragePermanent, @"Should consider primitive properties permanent");
}

- (void)testObjectAssignPermanent
{
	XCTAssertEqual([MTLStorageBehaviorModel storageBehaviorForPropertyWithKey:@"assignProperty"], MTLPropertyStoragePermanent, @"Should consider object-type assign properties permanent");
}

- (void)testObjectStrongPermanent
{
	XCTAssertEqual([MTLStorageBehaviorModel storageBehaviorForPropertyWithKey:@"strongProperty"], MTLPropertyStoragePermanent, @"Should consider object-type strong properties permanent");
}

- (void)testIgnoreDynamicReadonly
{
	XCTAssertEqual([MTLStorageBehaviorModel storageBehaviorForPropertyWithKey:@"notIvarBacked"], MTLPropertyStorageNone, @"Should ignore readonly properties without backing ivar");
}

@end

@interface MTLModelBasicDictionaryTestCase : XCTestCase
@end

@implementation MTLModelBasicDictionaryTestCase {
	MTLEmptyTestModel *emptyModel;
	NSDictionary *values;
	MTLTestModel *model;
}

- (void)setUp
{
	[super setUp];

	emptyModel = [[MTLEmptyTestModel alloc] init];
	XCTAssertNotNil(emptyModel);

	values = @{
		@"name": @"foobar",
		@"count": @(5),
		@"nestedName": @"fuzzbuzz",
		@"weakModel": emptyModel,
	};

	NSError *error = nil;
	model = [[MTLTestModel alloc] initWithDictionary:values error:&error];
	XCTAssertNotNil(model);
	XCTAssertNil(error);
}

- (void)testWithGivenValues
{
	XCTAssertEqualObjects(model.name, @"foobar");
	XCTAssertEqual(model.count, (NSUInteger)5);
	XCTAssertEqualObjects(model.nestedName, @"fuzzbuzz");
	XCTAssertEqualObjects(model.weakModel, emptyModel);

	XCTAssertEqualObjects(model.dictionaryValue, values);
	XCTAssertEqualObjects([model dictionaryWithValuesForKeys:values.allKeys], values);
}

- (void)testCompareWithMatchingModel
{
	XCTAssertEqualObjects(model, model);

	MTLTestModel *matchingModel = [[MTLTestModel alloc] initWithDictionary:values error:NULL];
	XCTAssertEqualObjects(model, matchingModel);
	XCTAssertEqual(model.hash, matchingModel.hash);
	XCTAssertEqualObjects(model.dictionaryValue, matchingModel.dictionaryValue);
}

- (void)testCompareWithDifferentModel
{
	MTLTestModel *differentModel = [[MTLTestModel alloc] init];
	XCTAssertNotEqualObjects(model, differentModel);
	XCTAssertNotEqualObjects(model.dictionaryValue, differentModel.dictionaryValue);
}

- (void)testCopying
{
	MTLTestModel *copiedModel = [model copy];
	XCTAssertEqualObjects(copiedModel, model);
	XCTAssertNotEqual(copiedModel, model);
}

- (void)testWeakEquality
{
	MTLTestModel *copiedModel = [model copy];
	copiedModel.weakModel = nil;

	XCTAssertEqualObjects(model, copiedModel);
}

@end

@interface MTLModelSubclassMergingTestCase : XCTestCase
@end

@implementation MTLModelSubclassMergingTestCase {
	MTLTestModel *superclass;
	MTLSubclassTestModel *subclass;
}

- (void)setUp
{
	[super setUp];

	superclass = [MTLTestModel modelWithDictionary:@{
		@"name": @"foo",
		@"count": @5
	} error:NULL];

	XCTAssertNotNil(superclass);

	subclass = [MTLSubclassTestModel modelWithDictionary:@{
		@"name": @"bar",
		@"count": @3,
		@"generation": @1,
		@"role": @"subclass"
	} error:NULL];

	XCTAssertNotNil(subclass);
}

- (void)testMergeFromSubclass
{
	[superclass mergeValuesForKeysFromModel:subclass];

	XCTAssertEqualObjects(superclass.name, @"bar");
	XCTAssertEqual(superclass.count, (NSUInteger)8);
}

- (void)testMergeFromSuperclass
{
	[subclass mergeValuesForKeysFromModel:superclass];

	XCTAssertEqualObjects(subclass.name, @"foo");
	XCTAssertEqual(subclass.count, (NSUInteger)8);
	XCTAssertEqualObjects(subclass.generation, @1);
	XCTAssertEqualObjects(subclass.role, @"subclass");
}

@end
