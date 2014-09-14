//
//  MTLTestModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@import Mantle;

extern NSString * const MTLTestModelErrorDomain;
extern const NSInteger MTLTestModelNameTooLong;
extern const NSInteger MTLTestModelNameMissing;



@interface MTLEmptyTestModel : MTLModel
@end

@interface MTLTestModel : MTLModel

// Defaults to 1. This changes the behavior of some of the receiver's methods to
// emulate a migration.
+ (void)setModelVersion:(NSUInteger)version;

// Must be less than 10 characters.
@property (nonatomic, copy) NSString *name;

// Defaults to 1. When two models are merged, their counts are added together.
@property (nonatomic, assign) NSUInteger count;

// This property should not be encoded into new archives.
@property (nonatomic, copy) NSString *nestedName;

// Should not be stored in the dictionary value.
@property (nonatomic, copy, readonly) NSString *dynamicName;

// Has MTLPropertyStorageTransitory.
@property (nonatomic, weak) MTLEmptyTestModel *weakModel;

@end

@interface MTLSubclassTestModel : MTLTestModel

// Properties to test merging between subclass and superclass
@property (nonatomic, copy) NSString *role;
@property (nonatomic, copy) NSNumber *generation;

@end

@interface MTLValidationModel : MTLModel

// Defaults to nil, which is not considered valid.
@property (nonatomic, copy) NSString *name;

@end

// Returns a default name of 'foobar' when validateName:error: is invoked
@interface MTLSelfValidatingModel : MTLValidationModel
@end

@interface MTLStorageBehaviorModel : MTLModel

@property (readonly, nonatomic, assign) BOOL primitive;

@property (readonly, nonatomic, assign) id assignProperty;
@property (readonly, nonatomic, weak) id weakProperty;
@property (readonly, nonatomic, strong) id strongProperty;

@end
