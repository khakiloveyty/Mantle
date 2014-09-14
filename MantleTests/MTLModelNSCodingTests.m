//
//  MTLModelNSCodingTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

@import Foundation;
@import XCTest;
@import Mantle;

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
}

- (MTLTestModel *)archiveAndUnarchiveModel
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
    XCTAssertNotNil(data);
    
    MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertNotNil(unarchivedModel);
    
    return unarchivedModel;
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
}

- (void)testUnconditionalProperties
{
	XCTAssertEqualObjects([self archiveAndUnarchiveModel], model);
}

- (void)testExcludedProperties
{
	model.nestedName = @"foobar";

	MTLTestModel *unarchivedModel = [self archiveAndUnarchiveModel];
	XCTAssertNil(unarchivedModel.nestedName);
	XCTAssertNotEqualObjects(unarchivedModel, model);

	model.nestedName = nil;
	XCTAssertEqualObjects(unarchivedModel, model);
}

- (void)testConditionalPropertiesFail
{
	model.weakModel = emptyModel;

	MTLTestModel *unarchivedModel = [self archiveAndUnarchiveModel];
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

@end
