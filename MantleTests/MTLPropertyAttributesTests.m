//
//  MTLPropertyAttributesTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2011-03-06 as part of libextobjc.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

@import Foundation;
@import XCTest;
@import Mantle;
#import "MTLReflection.h"

@interface RuntimeTestClass : NSObject

@property (nonatomic, assign, getter = isNormalBool, readonly) BOOL normalBool;
@property (nonatomic, strong, getter = whoopsWhatArray, setter = setThatArray:) NSArray *array;
@property (copy) NSString *normalString;
@property (unsafe_unretained) id untypedObject;
@property (nonatomic, weak) NSObject *weakObject;

@end

@implementation RuntimeTestClass

@synthesize normalBool = _normalBool;
@synthesize array = m_array;
@synthesize normalString;

- (NSObject *)weakObject {
	return nil;
}

- (void)setWeakObject:(NSObject *__unused)weakObject { }

@dynamic untypedObject;

@end

@interface MTLPropertyAttributesTests : XCTestCase

@end

@implementation MTLPropertyAttributesTests

- (void)testPropertyAttributesForBOOL {
    MTLPropertyAttributes attributes = MTLGetAttributesForProperty(RuntimeTestClass.class, @"normalBool");
	XCTAssertNotEqual(attributes.name, NULL);

	XCTAssertTrue(attributes.readonly);
	XCTAssertTrue(attributes.nonatomic);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyAssign);

    XCTAssertTrue(attributes.hasIvar);
    XCTAssertFalse(attributes.isObjectType);
	XCTAssertNil(attributes.objectClass);
}

- (void)testPropertyAttributesForArray {
    MTLPropertyAttributes attributes = MTLGetAttributesForProperty(RuntimeTestClass.class, @"array");
    XCTAssertNotEqual(attributes.name, NULL);

	XCTAssertFalse(attributes.readonly);
	XCTAssertTrue(attributes.nonatomic);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyRetain);

    XCTAssertTrue(attributes.hasIvar);
    XCTAssertTrue(attributes.isObjectType);
	XCTAssertEqualObjects(attributes.objectClass, NSArray.class);
}

- (void)testPropertyAttributesForNormalString {
    MTLPropertyAttributes attributes = MTLGetAttributesForProperty(RuntimeTestClass.class, @"normalString");
    XCTAssertNotEqual(attributes.name, NULL);

	XCTAssertFalse(attributes.readonly);
	XCTAssertFalse(attributes.nonatomic);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyCopy);
    
    XCTAssertTrue(attributes.hasIvar);
    XCTAssertTrue(attributes.isObjectType);
	XCTAssertEqualObjects(attributes.objectClass, NSString.class);
}

- (void)testPropertyAttributesForUntypedObject {
    MTLPropertyAttributes attributes = MTLGetAttributesForProperty(RuntimeTestClass.class, @"untypedObject");
    XCTAssertNotEqual(attributes.name, NULL);

	XCTAssertFalse(attributes.readonly);
	XCTAssertFalse(attributes.nonatomic);
	XCTAssertTrue(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyAssign);

    XCTAssertFalse(attributes.hasIvar);
    XCTAssertTrue(attributes.isObjectType);
	XCTAssertNil(attributes.objectClass);
}

- (void)testPropertyAttributesForWeakObject {
    MTLPropertyAttributes attributes = MTLGetAttributesForProperty(RuntimeTestClass.class, @"weakObject");
    XCTAssertNotEqual(attributes.name, NULL);
    
    XCTAssertFalse(attributes.readonly);
    XCTAssertTrue(attributes.nonatomic);
    XCTAssertFalse(attributes.dynamic);
    XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyWeak);
    
    XCTAssertFalse(attributes.hasIvar);
    XCTAssertTrue(attributes.isObjectType);
    XCTAssertEqualObjects(attributes.objectClass, NSObject.class);
}

@end
