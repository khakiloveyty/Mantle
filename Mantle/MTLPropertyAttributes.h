//
//  MTLPropertyAttributes.h
//  Mantle
//
//  Created by Zach Waldowski on 3/28/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

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
@interface MTLPropertyAttributes : NSObject

/**
 Enumerates the names of properties for the given class hierarchy, starting at
 the given class, and continuing up until (but not including) a given class.

 The given block will be invoked multiple times for any properties declared on
 each class in the hierarchy.
 */
+ (void)enumeratePropertyNamesOfClass:(Class)cls untilClass:(Class)endCls usingBlock:(void (^)(NSString *propertyName))block;

/**
 Returns property attributes for a given property on a given class.
 */
+ (instancetype)propertyNamed:(NSString *)propertyName class:(Class)cls reusingAttributes:(inout MTLPropertyAttributes **)attributesRef;

/**
 Returns property attributes for a given property on a given protocol.
 */
+ (instancetype)propertyNamed:(NSString *)propertyName protocol:(Protocol *)proto reusingAttributes:(inout MTLPropertyAttributes **)attributesRef;

/**
 * The name of this property.
 */
@property (nonatomic, copy, readonly) NSString *propertyName;

/**
 * Whether this property was declared with the \c readonly attribute.
 */
@property (nonatomic, readonly, getter = isReadonly) BOOL readonly;

/**
 * Whether this property was declared with the \c nonatomic attribute.
 */
@property (nonatomic, readonly, getter = isNonatomic) BOOL nonatomic;

/**
 * The memory management policy for this property. This will always be
 * #MTLPropertyMemoryPolicyAssign if #readonly is \c YES.
 */
@property (nonatomic, readonly) MTLPropertyMemoryPolicy memoryPolicy;

/**
 * Whether the property is eligible for garbage collection.
 */
@property (nonatomic, readonly) BOOL canBeCollected;

/**
 * Whether this property is defined with \c \@dynamic.
 */
@property (nonatomic, readonly, getter = isDynamic) BOOL dynamic;

/**
 * The selector for the getter of this property. This will reflect any
 * custom \c getter= attribute provided in the property declaration, or the
 * inferred getter name otherwise.
 */
@property (nonatomic, readonly) SEL getter;

/**
 * The selector for the setter of this property. This will reflect any
 * custom \c setter= attribute provided in the property declaration, or the
 * inferred setter name otherwise.
 *
 * @note If #readonly is \c YES, this value will represent what the setter
 * \e would be, if the property were writable.
 */
@property (nonatomic, readonly) SEL setter;

/**
 * The backing instance variable for this property, or \c NULL if \c
 * \c @synthesize was not used, and therefore no instance variable exists. This
 * would also be the case if the property is implemented dynamically.
 */
@property (nonatomic, readonly) const char *ivar;

/**
 * If this property is defined as being an instance of a specific class,
 * this will be the class object representing it.
 *
 * This will be \c nil if the property was defined as type \c id, if the
 * property is not of an object type, or if the class could not be found at
 * runtime.
 */
@property (nonatomic, readonly) Class objectClass;

/**
 * The type encoding for the value of this property. This is the type as it
 * would be returned by the \c \@encode() directive.
 */
@property (nonatomic, readonly) const char *type;

@end