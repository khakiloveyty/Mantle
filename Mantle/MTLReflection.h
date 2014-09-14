//
//  MTLReflection.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

@import Foundation;
#import "MTLModelProtocol.h"

/**
 * Describes the memory management policy of a property.
 */
typedef NS_ENUM(int8_t, MTLPropertyMemoryPolicy) {
    /**
     * The value is assigned.
     */
    MTLPropertyMemoryPolicyAssign,
    
    /**
     * The value is retained.
     */
    MTLPropertyMemoryPolicyRetain,
    
    /**
     * The value is copied.
     */
    MTLPropertyMemoryPolicyCopy,
    
    /**
     * The value is zeroing-weak-referenced.
     */
    MTLPropertyMemoryPolicyWeak
};

/**
 * Describes the attributes and type information of an Objective-C property.
 */
typedef const struct {
    /**
     * Returns property attributes for a given property on a given class.
     */
    const char *name;
    
    /**
     * Whether this property was declared with the \c readonly attribute.
     */
    BOOL readonly;
    
    /**
     * Whether this property was declared with the \c nonatomic attribute.
     */
    BOOL nonatomic;
    
    /**
     * Whether this property is defined with \c \@dynamic.
     */
    BOOL dynamic;
    
    /**
     * The memory management policy for this property. This will always be
     * #MTLPropertyMemoryPolicyAssign if #readonly is \c YES.
     */
    MTLPropertyMemoryPolicy memoryPolicy;
    
    /**
     * Whether this property was not used with \c @synthesize or is implemented
     * dynamically.
     */
    BOOL hasIvar;
    
    /**
     * Whether this property is typed as an Objective-C compatible object.
     */
    BOOL isObjectType;
    
    /**
     * If this property is defined as being an instance of a specific class,
     * this will be the class object representing it.
     *
     * This will be \c Nil if the property was defined as type \c id, if the
     * property is not of an object type, or if the class could not be found at
     * runtime.
     */
    Class objectClass;
} MTLPropertyAttributes;

/**
 * Enumerates the names of properties for the given class hierarchy, starting at
 * the given class, and continuing up until (but not including) the given class.
 *
 * The given block will be invoked multiple times for any properties declared on
 * each class in the hierarchy.
 */
extern void MTLEnumeratePropertiesUsingBlock(Class fromCls, Class endClass, void(^block)(NSString *propertyName));

/**
 * Returns property attributes for a given property on a given class.
 */
extern MTLPropertyAttributes MTLGetAttributesForProperty(Class cls, NSString *propertyName);


// Creates a selector from a key and a constant prefix and suffix.
//
// prefix - An optional string to prepend to the key as part of the selector.
// key    - The key to insert into the generated selector. This key should be in
//          its natural case; if prefixed, it will have its first letter
//          capitalized.
// suffix - A string to append to the key as part of the selector.
//
// Returns a selector, or NULL if the input strings cannot form a valid
// selector.
SEL MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix) __attribute__((pure, nonnull(2, 3)));

// Enumerable object representing the property keys of the given model class.
//
// Enumerating using the returned object will be at best be more efficient than
// just enumerating through the +propertyKeys of the given model class.
//
// class - A class conforming to MTLModel.
//
// Returns an object conforming to the NSFastEnumeration protocol.
extern id <NSFastEnumeration> MTLGetPropertyKeysEnumerable(Class <MTLModel> cls);

// Creates mapping from property keys to a given value.
//
// This function will be more efficient than the manual creation of a dictionary
// with the property keys of the given model class.
//
// class - A class conforming to MTLModel.
//
// Returns a dictionary that maps all properties of the given class to
// the results of the given block.
extern NSDictionary *MTLCopyPropertyKeyMapUsingBlock(Class <MTLModel> cls, id(^block)(NSString *propertyName, BOOL *stop)) __attribute__((nonnull(2)));
