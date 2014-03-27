//
//  MTLManagedObjectAdapterTests.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-17.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLCoreDataObjects.h"
#import "MTLCoreDataTestModels.h"

@interface MTLManagedObjectAdapterTests : XCTestCase {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSPersistentStore *store;
	NSManagedObjectContext *context;
}

@end

@implementation MTLManagedObjectAdapterTests

- (void)setUp
{
    [super setUp];

	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:@[ [NSBundle bundleForClass:self.class] ]];
	XCTAssertNotNil(model);

	if (!persistentStoreCoordinator) {
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	}
	XCTAssertNotNil(persistentStoreCoordinator);

	store = [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
	XCTAssertNotNil(store);
}

- (void)tearDown
{
	[context reset];
	context = nil;

	XCTAssertTrue([persistentStoreCoordinator removePersistentStore:store error:NULL]);
}

- (void)testMainQueueContextDeadlock
{
	context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	XCTAssertNotNil(persistentStoreCoordinator);

	context.undoManager = nil;
	context.persistentStoreCoordinator = persistentStoreCoordinator;

	MTLParent *parent = [MTLParent insertInManagedObjectContext:context];
	XCTAssertNotNil(parent);

	parent.string = @"foobar";

	NSError *error = nil;
	MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
	XCTAssertTrue([parentModel isKindOfClass:MTLParentTestModel.class]);
	XCTAssertNil(error);
}

- (void)testSerializeWithFailingChildren
{
	context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	XCTAssertNotNil(context);

	context.undoManager = nil;
	context.persistentStoreCoordinator = persistentStoreCoordinator;

	NSEntityDescription *parentEntity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
	XCTAssertNotNil(parentEntity);

	NSEntityDescription *childEntity = [NSEntityDescription entityForName:@"BadChild" inManagedObjectContext:context];
	XCTAssertNotNil(childEntity);

	MTLParentTestModel *parentModel = [MTLParentTestModel modelWithDictionary:@{
		@"date": [NSDate date],
		@"numberString": @"1234",
		@"requiredString": @"foobar"
	} error:NULL];
	XCTAssertNotNil(parentModel);

	NSMutableArray *orderedChildren = [NSMutableArray array];

	for (NSUInteger i = 3; i < 6; i++) {
		MTLBadChildTestModel *child = [MTLBadChildTestModel modelWithDictionary:@{
			@"childID": @(i)
		} error:NULL];
		XCTAssertNotNil(child);

		[orderedChildren addObject:child];
	}

	parentModel.orderedChildren = orderedChildren;

	NSError *error = nil;
	MTLParent *parent = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
	XCTAssertNil(parent);
	XCTAssertNotNil(error);
	XCTAssertTrue([context save:&error]);
	XCTAssertNotNil(error);
}

@end

@interface MTLConfinedContextManagedObjectAdapterTests : MTLManagedObjectAdapterTests {
	NSEntityDescription *parentEntity;
	NSEntityDescription *childEntity;
}

@end

@implementation MTLConfinedContextManagedObjectAdapterTests

- (void)setUp
{
	[super setUp];

	context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	XCTAssertNotNil(context);

	context.undoManager = nil;
	context.persistentStoreCoordinator = persistentStoreCoordinator;

	parentEntity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:context];
	XCTAssertNotNil(parentEntity);

	childEntity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:context];
	XCTAssertNotNil(childEntity);
}

- (void)testDeserializeWithChildren
{
	NSError *error = nil;

	NSDate *date = [NSDate date];
	NSString *numberString = @"123";
	NSString *requiredString = @"foobar";
	NSURL *URL = [NSURL URLWithString:@"http://github.com"];

	MTLParent *parent = [MTLParent insertInManagedObjectContext:context];
	XCTAssertNotNil(parent);

	for (NSUInteger i = 0; i < 3; i++) {
		MTLChild *child = [MTLChild insertInManagedObjectContext:context];
		XCTAssertNotNil(child);

		child.childID = @(i);
		[parent addOrderedChildrenObject:child];
	}

	for (NSUInteger i = 3; i < 6; i++) {
		MTLChild *child = [MTLChild insertInManagedObjectContext:context];
		XCTAssertNotNil(child);

		child.childID = @(i);
		[parent addUnorderedChildrenObject:child];
	}

	parent.string = requiredString;

	XCTAssertTrue([context save:&error]);
	XCTAssertNil(error);

	// Make sure that pending changes are picked up too.
	[parent setValue:@(numberString.integerValue) forKey:@"number"];
	[parent setValue:date forKey:@"date"];
	[parent setValue:URL.absoluteString forKey:@"url"];

	MTLParentTestModel *parentModel = [MTLManagedObjectAdapter modelOfClass:MTLParentTestModel.class fromManagedObject:parent error:&error];
	XCTAssertTrue([parentModel isKindOfClass:MTLParentTestModel.class]);
	XCTAssertNil(error);

	XCTAssertEqualObjects(parentModel.date, date);
	XCTAssertEqualObjects(parentModel.numberString, numberString);
	XCTAssertEqualObjects(parentModel.requiredString, requiredString);
	XCTAssertEqualObjects(parentModel.URL, URL);

	XCTAssertEqual(parentModel.orderedChildren.count, (NSUInteger)3);
	XCTAssertEqual(parentModel.unorderedChildren.count, (NSUInteger)3);

	for (NSUInteger i = 0; i < 3; i++) {
		MTLChildTestModel *child = parentModel.orderedChildren[i];
		XCTAssertTrue([child isKindOfClass:MTLChildTestModel.class]);

		XCTAssertEqual(child.childID, i);
		XCTAssertNil(child.parent1);
		XCTAssertEqual(child.parent2, parentModel);
	}

	for (MTLChildTestModel *child in parentModel.unorderedChildren) {
		XCTAssertTrue([child isKindOfClass:MTLChildTestModel.class]);

		XCTAssertTrue(child.childID >= 3);
		XCTAssertTrue(child.childID < 6);

		XCTAssertEqual(child.parent1, parentModel);
		XCTAssertNil(child.parent2);
	}
}

@end

@interface MTLConfinedContextManagedObjectSerializeTests : MTLConfinedContextManagedObjectAdapterTests
@end

@implementation MTLConfinedContextManagedObjectSerializeTests {
	MTLParentTestModel *parentModel;
}

- (void)setUp
{
	[super setUp];

	parentModel = [MTLParentTestModel modelWithDictionary:@{
		@"date": [NSDate date],
		@"numberString": @"1234",
		@"requiredString": @"foobar"
	} error:NULL];
	XCTAssertNotNil(parentModel);

	NSMutableArray *orderedChildren = [NSMutableArray array];
	NSMutableSet *unorderedChildren = [NSMutableSet set];

	for (NSUInteger i = 0; i < 3; i++) {
		MTLChildTestModel *child = [MTLChildTestModel modelWithDictionary:@{
			@"childID": @(i),
			@"parent2": parentModel
		} error:NULL];
		XCTAssertNotNil(child);

		[orderedChildren addObject:child];
	}

	for (NSUInteger i = 3; i < 6; i++) {
		MTLChildTestModel *child = [MTLChildTestModel modelWithDictionary:@{
			@"childID": @(i),
			@"parent1": parentModel
		} error:NULL];
		XCTAssertNotNil(child);

		[unorderedChildren addObject:child];
	}

	parentModel.orderedChildren = orderedChildren;
	parentModel.unorderedChildren = unorderedChildren;
}

- (void)testInsertWithChildren
{
	__block NSError *error = nil;
	MTLParent *parent = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
	XCTAssertNotNil(parent);
	XCTAssertTrue([parent isKindOfClass:MTLParent.class]);
	XCTAssertNil(error);

	XCTAssertEqualObjects(parent.entity, parent.entity);
	XCTAssertTrue([context.insertedObjects containsObject:parent]);

	XCTAssertEqualObjects(parent.date, parentModel.date);
	XCTAssertEqualObjects(parent.number.stringValue, parentModel.numberString);
	XCTAssertEqualObjects(parent.string, parentModel.requiredString);

	XCTAssertEqual(parent.orderedChildren.count, (NSUInteger)3);

	XCTAssertEqual(parent.unorderedChildren.count, (NSUInteger)3);

	for (NSUInteger i = 0; i < 3; i++) {
		MTLChild *child = parent.orderedChildren[i];
		XCTAssertTrue([child isKindOfClass:MTLChild.class]);

		XCTAssertEqualObjects(child.entity, childEntity);
		XCTAssertTrue([context.insertedObjects containsObject:child]);

		XCTAssertEqualObjects(child.childID, @(i));
		XCTAssertNil(child.parent1);
		XCTAssertEqualObjects(child.parent2, parent);
	}

	for (MTLChild *child in parent.unorderedChildren) {
		XCTAssertTrue([child isKindOfClass:MTLChild.class]);

		XCTAssertEqualObjects(child.entity, childEntity);
		XCTAssertTrue([context.insertedObjects containsObject:child]);

		XCTAssertTrue([child.childID unsignedIntegerValue] >= 3);
		XCTAssertTrue([child.childID unsignedIntegerValue] < 6);

		XCTAssertEqual(child.parent1, parent);
		XCTAssertNil(child.parent2);
	}

	XCTAssertTrue([context save:&error]);
	XCTAssertNil(error);
};

- (void)testInsertFail
{
	MTLFailureModel *failureModel = [MTLFailureModel modelWithDictionary:@{
		@"notSupported": @"foobar"
	} error:NULL];

	NSError *error = nil;
	NSManagedObject *managedObject = [MTLManagedObjectAdapter managedObjectFromModel:failureModel insertingIntoContext:context error:&error];

	XCTAssertNil(managedObject);
	XCTAssertNotNil(error);
}

- (void)testValidateAttributeFail
{
	MTLParentTestModel *failureModel = [MTLParentTestModel modelWithDictionary:@{} error:NULL];

	NSError *error = nil;
	NSManagedObject *managedObject = [MTLManagedObjectAdapter managedObjectFromModel:failureModel insertingIntoContext:context error:&error];

	XCTAssertNil(managedObject);
	XCTAssertNotNil(error);
}

- (void)testValidateForInsertFail
{
	MTLParentIncorrectTestModel *failureModel = [MTLParentIncorrectTestModel modelWithDictionary:@{} error:NULL];

	NSError *error = nil;
	NSManagedObject *managedObject = [MTLManagedObjectAdapter managedObjectFromModel:failureModel insertingIntoContext:context error:&error];

	XCTAssertNil(managedObject);
	XCTAssertNotNil(error);
}

- (void)testUniquenessConstraint
{
	NSError *errorOne;
	MTLParent *parentOne = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&errorOne];
	XCTAssertNotNil(parentOne);
	XCTAssertNil(errorOne);

	NSError *errorTwo;
	MTLParent *parentTwo = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&errorTwo];
	XCTAssertNotNil(parentTwo);
	XCTAssertNil(errorTwo);

	XCTAssertEqualObjects(parentOne.objectID, parentTwo.objectID);
};

- (void)testUniquenessPropertyTransform
{
	[parentModel setValue:NSNull.null forKey:@"numberString"];

	NSError *error;
	MTLParent *parent = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];

	XCTAssertNil(parent);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, MTLCoreDataTestModelsDomain);
};

- (void)testUpdateRelationships
{
	NSError *error;
	MTLParent *parentOne = [MTLManagedObjectAdapter managedObjectFromModel:parentModel insertingIntoContext:context error:&error];
	XCTAssertNotNil(parentOne);
	XCTAssertNil(error);
	XCTAssertEqual(parentOne.orderedChildren.count, (NSUInteger)3);
	XCTAssertEqual(parentOne.unorderedChildren.count, (NSUInteger)3);

	MTLChild *child1Parent1 = parentOne.orderedChildren[0];
	MTLChild *child2Parent1 = parentOne.orderedChildren[1];
	MTLChild *child3Parent1 = parentOne.orderedChildren[2];

	MTLParentTestModel *parentModelCopy = [parentModel copy];
	[[parentModelCopy mutableOrderedSetValueForKey:@"orderedChildren"] removeObjectAtIndex:1];

	MTLChildTestModel *childToDeleteModel = [parentModelCopy.unorderedChildren anyObject];
	[[parentModelCopy mutableSetValueForKey:@"unorderedChildren"] removeObject:childToDeleteModel];

	MTLParent *parentTwo = [MTLManagedObjectAdapter managedObjectFromModel:parentModelCopy insertingIntoContext:context error:&error];
	XCTAssertNotNil(parentTwo);
	XCTAssertNil(error);
	XCTAssertEqual(parentTwo.orderedChildren.count, (NSUInteger)2);
	XCTAssertEqual(parentTwo.unorderedChildren.count, (NSUInteger)2);

	for (MTLChild *child in parentTwo.orderedChildren) {
		XCTAssertNotEqualObjects(child.childID, child2Parent1.childID);
	}

	for (MTLChild *child in parentTwo.unorderedChildren) {
		XCTAssertNotEqualObjects(child.childID, @(childToDeleteModel.childID));
	}

	MTLChild *child1Parent2 = parentTwo.orderedChildren[0];
	MTLChild *child2Parent2 = parentTwo.orderedChildren[1];
	XCTAssertEqualObjects(child1Parent2, child1Parent1);
	XCTAssertEqualObjects(child2Parent2, child3Parent1);
};

@end
