//
//  MTLReflection.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// Describes the simple attributes of an Obj-C property.
typedef NS_OPTIONS(uint32_t, mtl_property_attr_t) {
	/// Set if @synthesize was used and @dynamic was not.
	mtl_property_hasIvar           = 1 << 0,
	/// Set if (readonly) was used with this property.
	mtl_property_readonly          = 1 << 1,
	/// Set if (weak) was used with this property and it's an ObjC object.
	mtl_property_weak              = 1 << 2,
	/// Set if @dynamic was used with this property.
	mtl_property_dynamic           = 1 << 3,
	/// Set if this property defines and/or responds to a getter.
	mtl_property_hasGetter         = 1 << 4,
	/// Set if this property defines and/or responds to a setter.
	mtl_property_hasSetter         = 1 << 5
};

/// Creates a selector from a key and a constant prefix and suffix.
///
/// prefix - A string to prepend to the key as part of the selector.
/// key    - The key to insert into the generated selector. This key should be
///          in its natural case, and will have its first letter capitalized if
///          prefixed.
/// suffix - A string to append to the key as part of the selector.
///
/// Returns a selector, or NULL if the input strings cannot form a valid
/// selector.
MANTLE_PRIVATE MANTLE_PURE
SEL _Nullable MTLSelectorWithKeyPattern(const char *prefix, NSString *key, const char *suffix);

/// Copies the type encoding string and, if possible, the metatype for an
/// Objective-C property.
///
/// cls          - The class on which to query for the `propertyName`.
/// propertyName - The name of the keyed property name; for example, if the
///                `cls` specifies `@property NSString *name;`, `@"name"`.
/// outClass     - On output, the Objective-C class referenced by the property,
///                or Nil if the property references a primitive type.
///
/// Returns a type-encoding string (i.e., the format used by @encode), or nil
/// if the property doesn't exist.
MANTLE_PRIVATE
NSString *_Nullable MTLTypeEncodingForProperty(Class cls, NSString *propertyName, _Nullable Class *_Nullable outClass);

/// Returns synthesized attributes information about an Objective-C property.
///
/// cls          - The class on which to query for the `propertyName`.
/// propertyName - The name of the keyed property name; for example, if the
///                `cls` specifies `@property NSString *name;`, `@"name"`.
///
/// Returns attributes described by \c mtl_property_attr_t, or \c 0 if some
/// part of the lookup failed.
MANTLE_PRIVATE
mtl_property_attr_t MTLAttributesForProperty(Class cls, NSString *key);

/// Returns whether the Objective-C property references an Objective-C type
/// using weak references.
///
/// cls          - The class on which to query for the `propertyName`.
/// propertyName - The name of the keyed property name; for example, if the
///                `cls` specifies `@property NSString *name;`, `@"name"`.
///
/// Returns YES if the property was declared using the `weak` attribute.
NS_INLINE
BOOL MTLPropertyIsWeak(Class cls, NSString *propertyName) {
	return (MTLAttributesForProperty(cls, propertyName) & mtl_property_weak) != 0;
}

/// Returns `YES` if the property attributes describe a property that is not
/// dynamic, but nevertheless has no ivar, getter, or setter.
NS_INLINE
BOOL MTLPropertyIsRuntime(mtl_property_attr_t attr) {
	return (attr & mtl_property_dynamic) != 0 && (attr & mtl_property_hasIvar) == 0 && (attr & mtl_property_hasGetter) == 0 && (attr & mtl_property_hasSetter) == 0;
}

/// Returns `YES` if the property attributes describe a property that is
/// readonly and has no ivar.
NS_INLINE
BOOL MTLPropertyIsComputed(mtl_property_attr_t attr) {
	return (attr & mtl_property_readonly) != 0 && (attr & mtl_property_hasIvar) == 0;
}

#ifdef __APPLE__
MANTLE_PRIVATE
BOOL MTLIsDebugging(void);
#else
NS_INLINE
BOOL MTLIsDebugging(void) {
	return NO;
}
#endif

NS_ASSUME_NONNULL_END
