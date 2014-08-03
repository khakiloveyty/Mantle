//
//  MTLModelNSCodingTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

@interface MTLModelNSCodingTests : XCTestCase
@end

@implementation MTLModelNSCodingTests

- (void)testDefaultEncodingBehaviors
{
	NSDictionary *behaviors = MTLTestModel.encodingBehaviorsByPropertyKey;
	XCTAssertNotNil(behaviors);

	XCTAssertEqualObjects(behaviors[@"name"], @(MTLModelEncodingBehaviorUnconditional));
	XCTAssertEqualObjects(behaviors[@"count"], @(MTLModelEncodingBehaviorUnconditional));
	XCTAssertEqualObjects(behaviors[@"weakModel"], @(MTLModelEncodingBehaviorConditional));
	XCTAssertNil(behaviors[@"dynamicName"]);
}

- (void)testDefaultAllowedClasses
{
	NSDictionary *allowedClasses = MTLTestModel.allowedSecureCodingClassesByPropertyKey;
	XCTAssertNotNil(allowedClasses);

	XCTAssertEqualObjects(allowedClasses[@"name"], @[ NSString.class ]);
	XCTAssertEqualObjects(allowedClasses[@"count"], @[ NSValue.class ]);
	XCTAssertEqualObjects(allowedClasses[@"weakModel"], @[ MTLEmptyTestModel.class ]);

	// Not encoded into archives.
	XCTAssertNil(allowedClasses[@"nestedName"]);
	XCTAssertNil(allowedClasses[@"dynamicName"]);
}

- (void)testVersion
{
	XCTAssertEqual(MTLEmptyTestModel.modelVersion, (NSUInteger)0);
}

@end

@interface MTLModelNSCodingArchivingTests : XCTestCase
@end

@implementation MTLModelNSCodingArchivingTests {
	MTLEmptyTestModel *emptyModel;
	MTLTestModel *model;
	NSDictionary *values;

	MTLTestModel *(^archiveAndUnarchiveModel)(void);
}

- (void)setUp
{
    [super setUp];

	emptyModel = [[MTLEmptyTestModel alloc] init];
	XCTAssertNotNil(emptyModel);

	values = @{
		@"name": @"foobar",
		@"count": @5,
	};

	NSError *error = nil;
	model = [[MTLTestModel alloc] initWithDictionary:values error:&error];
	XCTAssertNotNil(model);
	XCTAssertNil(error);

	__weak typeof(self) blockSelf = self;
	archiveAndUnarchiveModel = [^{
		typeof(self) self = blockSelf;

		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self->model];
		XCTAssertNotNil(data);

		MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		XCTAssertNotNil(unarchivedModel);

		return unarchivedModel;
	} copy];
}

- (void)testUnconditionalProperties
{
	XCTAssertEqualObjects(archiveAndUnarchiveModel(), model);
}

- (void)testExcludedProperties
{
	model.nestedName = @"foobar";

	MTLTestModel *unarchivedModel = archiveAndUnarchiveModel();
	XCTAssertNil(unarchivedModel.nestedName);
	XCTAssertNotEqualObjects(unarchivedModel, model);

	model.nestedName = nil;
	XCTAssertEqualObjects(unarchivedModel, model);
}

- (void)testConditionalPropertiesFail
{
	model.weakModel = emptyModel;

	MTLTestModel *unarchivedModel = archiveAndUnarchiveModel();
	XCTAssertNil(unarchivedModel.weakModel);
}

- (void)testConditionalProperties
{
	model.weakModel = emptyModel;

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@[ model, emptyModel ]];
	XCTAssertNotNil(data);

	NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	XCTAssertEqual(objects.count, (NSUInteger)2);
	XCTAssertEqualObjects(objects[1], emptyModel);

	MTLTestModel *unarchivedModel = objects[0];
	XCTAssertEqualObjects(unarchivedModel, model);
	XCTAssertEqualObjects(unarchivedModel.weakModel, emptyModel);
}

- (void)testCustomLogin
{
	MTLTestModel.modelVersion = 0;

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
	XCTAssertNotNil(data);

	MTLTestModel.modelVersion = 1;

	MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	XCTAssertNotNil(unarchivedModel);
	XCTAssertEqualObjects(unarchivedModel.name, @"M: foobar");
	XCTAssertEqual(unarchivedModel.count, (NSUInteger)5);
}

- (void)testOldFormat
{
	NSURL *archiveURL = [[NSBundle bundleForClass:self.class] URLForResource:@"MTLTestModel-OldArchive" withExtension:@"plist"];
	XCTAssertNotNil(archiveURL);

	MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithFile:archiveURL.path];
	XCTAssertNotNil(unarchivedModel);

	NSDictionary *expectedValues = @{
		@"name": @"foobar",
		@"count": @5,
		@"nestedName": @"fuzzbuzz",
		@"weakModel": NSNull.null,
	};
	
	XCTAssertEqualObjects(unarchivedModel.dictionaryValue, expectedValues);
}

@end
