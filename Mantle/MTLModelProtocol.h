//
//  MTLModelProtocol.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

// This protocol defines the minimal interface that classes need to implement to
// interact with Mantle adapters.
//
// It is intended for scenarios where inheriting from MTLModel is not feasible.
// However, clients are encouraged to subclass the MTLModel class if they can.
//
// Clients that wish to implement their own adapters should target classes
// conforming to this protocol rather than subclasses of MTLModel to ensure
// maximum compatibility.
@protocol MTLModel <NSObject, NSCopying>

// Initializes a new instance of the receiver using key-value coding, setting
// the keys and values in the given dictionary.
//
// dictionaryValue - Property keys and values to set on the instance. Any NSNull
//                   values will be converted to nil before being used. KVC
//                   validation methods will automatically be invoked for all of
//                   the properties given.
// error           - If not NULL, this may be set to any error that occurs
//                   (like a KVC validation error).
//
// Returns an initialized model object, or nil if validation failed.
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

// A dictionary representing the properties of the receiver.
//
// Combines the values corresponding to all +propertyKeys into a dictionary,
// with any nil values represented by NSNull.
//
// This property must never be nil.
@property (nonatomic, copy, readonly) NSDictionary *dictionaryValue;

// Initializes the receiver using key-value coding, setting the keys and values
// in the given dictionary.
//
// dictionaryValue - Property keys and values to set on the receiver. Any NSNull
//                   values will be converted to nil before being used. KVC
//                   validation methods will automatically be invoked for all of
//                   the properties given. If nil, this method is equivalent to
//                   -init.
// error           - If not NULL, this may be set to any error that occurs
//                   (like a KVC validation error).
//
// Returns an initialized model object, or nil if validation failed.
- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;

// Merges the value of the given key on the receiver with the value of the same
// key from the given model object, giving precedence to the other model object.
- (void)mergeValueForKey:(NSString *)key fromModel:(id<MTLModel>)model;

// Returns the keys for all @property declarations, except for `readonly`
// properties without ivars, or properties on MTLModel itself.
+ (NSSet *)propertyKeys;

// Validates the model.
//
// error - If not NULL, this may be set to any error that occurs during
//         validation
//
// Returns YES if the model is valid, or NO if the validation failed.
- (BOOL)validate:(NSError **)error;

@end
