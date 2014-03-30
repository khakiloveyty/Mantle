//
//  MTLPropertyAttributesTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2011-03-06 as part of libextobjc.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "MTLPropertyAttributes.h"

@protocol RuntimeTestProtocol <NSObject>

@property (nonatomic, weak) NSObject *weakObject;

@end

@interface RuntimeTestClass : NSObject <RuntimeTestProtocol>

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

- (void)setWeakObject:(NSObject *)weakObject { }

@dynamic untypedObject;

@end

@interface MTLPropertyAttributesTests : XCTestCase

@end

@implementation MTLPropertyAttributesTests

- (void)testPropertyAttributesForBOOL {
	MTLPropertyAttributes *attributes = nil;
	XCTAssertNoThrow(attributes = [MTLPropertyAttributes propertyNamed:@"normalBool" class:RuntimeTestClass.class reusingAttributes:NULL]);
	XCTAssertNotNil(attributes);

	XCTAssertTrue(attributes.readonly);
	XCTAssertTrue(attributes.nonatomic);
	XCTAssertFalse(attributes.canBeCollected);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyAssign);

	XCTAssertEqual(attributes.getter, @selector(isNormalBool));
	XCTAssertEqual(attributes.setter, NULL);

	XCTAssertFalse(strcmp(attributes.ivar, "_normalBool"));
	XCTAssertTrue(strlen(attributes.type) > 0);

	NSUInteger size = 0;
	NSGetSizeAndAlignment(attributes.type, &size, NULL);
	XCTAssertTrue(size > 0);

	XCTAssertNil(attributes.objectClass);
}

- (void)testPropertyAttributesForArray {
	MTLPropertyAttributes *attributes = nil;
	XCTAssertNoThrow(attributes = [MTLPropertyAttributes propertyNamed:@"array" class:RuntimeTestClass.class reusingAttributes:NULL]);
	XCTAssertNotNil(attributes);

	XCTAssertFalse(attributes.readonly);
	XCTAssertTrue(attributes.nonatomic);
	XCTAssertFalse(attributes.canBeCollected);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyRetain);

	XCTAssertEqual(attributes.getter, @selector(whoopsWhatArray));
	XCTAssertEqual(attributes.setter, @selector(setThatArray:));

	XCTAssertFalse(strcmp(attributes.ivar, "m_array"));
	XCTAssertTrue(strlen(attributes.type) > 0);

	NSUInteger size = 0;
	NSGetSizeAndAlignment(attributes.type, &size, NULL);
	XCTAssertTrue(size > 0);

	XCTAssertEqualObjects(attributes.objectClass, NSArray.class);
}

- (void)testPropertyAttributesForNormalString {
	MTLPropertyAttributes *attributes = nil;
	XCTAssertNoThrow(attributes = [MTLPropertyAttributes propertyNamed:@"normalString" class:RuntimeTestClass.class reusingAttributes:NULL]);
	XCTAssertNotNil(attributes);

	XCTAssertFalse(attributes.readonly);
	XCTAssertFalse(attributes.nonatomic);
	XCTAssertFalse(attributes.canBeCollected);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyCopy);

	XCTAssertEqual(attributes.getter, @selector(normalString));
	XCTAssertEqual(attributes.setter, @selector(setNormalString:));

	XCTAssertFalse(strcmp(attributes.ivar, "normalString"));
	XCTAssertTrue(strlen(attributes.type) > 0);

	NSUInteger size = 0;
	NSGetSizeAndAlignment(attributes.type, &size, NULL);
	XCTAssertTrue(size > 0);

	XCTAssertEqualObjects(attributes.objectClass, NSString.class);
}

- (void)testPropertyAttributesForUntypedObject {
	MTLPropertyAttributes *attributes = nil;
	XCTAssertNoThrow(attributes = [MTLPropertyAttributes propertyNamed:@"untypedObject" class:RuntimeTestClass.class reusingAttributes:NULL]);
	XCTAssertNotNil(attributes);

	XCTAssertFalse(attributes.readonly);
	XCTAssertFalse(attributes.nonatomic);
	XCTAssertFalse(attributes.canBeCollected);
	XCTAssertTrue(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyAssign);

	XCTAssertEqual(attributes.getter, @selector(untypedObject));
	XCTAssertEqual(attributes.setter, @selector(setUntypedObject:));

	XCTAssertEqual(attributes.ivar, NULL);
	XCTAssertTrue(strlen(attributes.type) > 0);

	NSUInteger size = 0;
	NSGetSizeAndAlignment(attributes.type, &size, NULL);
	XCTAssertTrue(size > 0);

	XCTAssertNil(attributes.objectClass);
}

- (void)commonTestPropertyAttributesForWeakObject:(MTLPropertyAttributes *)attributes {
	XCTAssertNotNil(attributes);

	XCTAssertFalse(attributes.readonly);
	XCTAssertTrue(attributes.nonatomic);
	XCTAssertFalse(attributes.canBeCollected);
	XCTAssertFalse(attributes.dynamic);
	XCTAssertEqual(attributes.memoryPolicy, MTLPropertyMemoryPolicyWeak);

	XCTAssertEqual(attributes.getter, @selector(weakObject), @"");
	XCTAssertEqual(attributes.setter, @selector(setWeakObject:), @"");

	XCTAssertEqual(attributes.ivar, NULL);
	XCTAssertTrue(strlen(attributes.type) > 0);

	NSUInteger size = 0;
	NSGetSizeAndAlignment(attributes.type, &size, NULL);
	XCTAssertTrue(size > 0);

	XCTAssertEqualObjects(attributes.objectClass, NSObject.class);
}

- (void)testPropertyAttributesForWeakObject {
	MTLPropertyAttributes *attributes = nil;
	XCTAssertNoThrow(attributes = [MTLPropertyAttributes propertyNamed:@"weakObject" class:RuntimeTestClass.class reusingAttributes:NULL]);
	[self commonTestPropertyAttributesForWeakObject:attributes];
}

- (void)testPropertyAttributesForWeakObjectInProtocol {
	MTLPropertyAttributes *attributes = nil;
	XCTAssertNoThrow(attributes = [MTLPropertyAttributes propertyNamed:@"weakObject" protocol:@protocol(RuntimeTestProtocol) reusingAttributes:NULL]);
	[self commonTestPropertyAttributesForWeakObject:attributes];
}

@end
