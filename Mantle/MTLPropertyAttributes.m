//
//  MTLPropertyAttributes.m
//  Mantle
//
//  Created by Zach Waldowski on 3/28/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLPropertyAttributes.h"
#import "MTLReflection.h"
#import <objc/runtime.h>

static inline objc_property_t MTLPropertyFromClass(NSString *propertyName, Class cls) {
	const char *name = propertyName.UTF8String;
	objc_property_t property = class_getProperty(cls, name);
	return property;
}

static inline objc_property_t MTLPropertyFromProtocol(NSString *propertyName, Protocol *protocol) {
	const char *name = propertyName.UTF8String;
	objc_property_t property = protocol_getProperty(protocol, name, YES, YES);
	if (!property) property = protocol_getProperty(protocol, name, NO, YES);
	if (!property) property = protocol_getProperty(protocol, name, YES, NO);
	if (!property) property = protocol_getProperty(protocol, name, NO, NO);
	return property;
}

@interface MTLPropertyAttributes () {
	struct {
		BOOL readonly;
		BOOL nonatomic;
		BOOL dynamic;
		BOOL canBeCollected;
	} _flags;
}

@property (nonatomic, readonly) objc_property_t property;
- (BOOL)setProperty:(objc_property_t)property;
- (BOOL)setPropertyWithName:(NSString *)propertyName fromClass:(Class)cls;
- (BOOL)setPropertyWithName:(NSString *)propertyName fromProtocol:(Protocol *)protocol;

@property (nonatomic, readonly) NSString *typeString;
@property (nonatomic, readonly) NSString *ivarString;

@end

@implementation MTLPropertyAttributes

+ (void)mtl_enumeratePropertiesOfClass:(Class)cls untilClass:(Class)endCls usingBlock:(void (^)(objc_property_t property))block
{
	if (endCls == NULL) endCls = [cls superclass];
	if (cls == NULL || cls == endCls || cls == NSObject.class) return;

	unsigned int count = 0;
	objc_property_t *properties = class_copyPropertyList(cls, &count);

	if (properties) {
		for (unsigned int i = 0; i < count; i++) {
			block(properties[i]);
		}

		free(properties);
	}

	[self mtl_enumeratePropertiesOfClass:[cls superclass] untilClass:endCls usingBlock:block];
}

+ (void)enumeratePropertyNamesFromClass:(Class)cls untilClass:(Class)endCls usingBlock:(void (^)(NSString *propertyName))block
{
	NSParameterAssert(block != NULL);
	
	[self mtl_enumeratePropertiesOfClass:cls untilClass:endCls usingBlock:^(objc_property_t property) {
		const char *propertyName = property_getName(property);
		NSString *name = [[NSString alloc] initWithBytesNoCopy:(void *)propertyName length:strlen(propertyName) encoding:NSUTF8StringEncoding freeWhenDone:NO];
		block(name);
	}];
}

+ (void)enumeratePropertiesFromClass:(Class)cls untilClass:(Class)endCls usingBlock:(void (^)(MTLPropertyAttributes *attributes))block
{
	NSParameterAssert(block != NULL);
	
	__block MTLPropertyAttributes *attributes = [[MTLPropertyAttributes alloc] initPrivate];
	[self mtl_enumeratePropertiesOfClass:cls untilClass:endCls usingBlock:^(objc_property_t property) {
		if (![attributes setProperty:property]) {
			return;
		}

		block(attributes);
	}];
}

+ (NSSet *)namesOfPropertiesFromClass:(Class)cls untilClass:(Class)endCls passingTest:(BOOL (^)(NSString *propertyName))block
{
	
	NSMutableSet *set = [NSMutableSet set];
	[self enumeratePropertyNamesFromClass:cls untilClass:endCls usingBlock:^(NSString *propertyName) {
		if (!block(propertyName)) { return; }
		[set addObject:propertyName];
	}];
	return [set copy];
}

+ (instancetype)propertyNamed:(NSString *)propertyName class:(Class)cls
{
	MTLPropertyAttributes *attributes = [[MTLPropertyAttributes alloc] initPrivate];
	if (![attributes setPropertyWithName:propertyName fromClass:cls]) {
		return nil;
	}
	return attributes;
}

+ (instancetype)propertyNamed:(NSString *)propertyName protocol:(Protocol *)proto
{
	MTLPropertyAttributes *attributes = [[MTLPropertyAttributes alloc] initPrivate];
	if (![attributes setPropertyWithName:propertyName fromProtocol:proto]) {
		return nil;
	}
	return attributes;
}

- (instancetype)init
{
	return (self = nil);
}

- (instancetype)initPrivate
{
	return (self = [super init]);
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p, \"%@\">", NSStringFromClass(self.class), (__bridge void *)self, self.name];
}

- (NSString *)debugDescription
{
	NSMutableArray *attributeItems = [NSMutableArray array];
	if (self.nonatomic) {
		[attributeItems addObject:@"nonatomic"];
	}
	
	switch (self.memoryPolicy) {
		case MTLPropertyMemoryPolicyRetain:
			[attributeItems addObject:@"strong"];
			break;
		case MTLPropertyMemoryPolicyCopy:
			[attributeItems addObject:@"copy"];
			break;
		case MTLPropertyMemoryPolicyWeak:
			[attributeItems addObject:@"weak"];
			break;
		default: break;
	}
	
	if (self.readonly) {
		[attributeItems addObject:@"readonly"];
	} else {
		[attributeItems addObject:@"readwrite"];
		[attributeItems addObject:[NSString stringWithFormat:@"setter = %@", NSStringFromSelector(self.setter)]];
	}
	
	[attributeItems addObject:[NSString stringWithFormat:@"getter = %@", NSStringFromSelector(self.getter)]];
	
	if (self.ivarString.length) {
		[attributeItems addObject:[NSString stringWithFormat:@"ivar = %@", self.ivarString]];
	}
	
	NSString *propertyAttributes = [attributeItems componentsJoinedByString:@", "];
	if (propertyAttributes.length) propertyAttributes = [NSString stringWithFormat:@"(%@) ", propertyAttributes];
	
	return [NSString stringWithFormat:@"<%@: %p> @property %@(%@) %@;", NSStringFromClass(self.class), (__bridge void *)self, propertyAttributes, self.typeString, self.name];
}

- (BOOL)isEqual:(MTLPropertyAttributes *)object
{
	if (![object isKindOfClass:self.class]) {
		return NO;
	}
	
	return _property == object.property;
}

- (NSUInteger)hash
{
	return (uintptr_t)_property >> 3;
}

#pragma mark -

- (BOOL)setPropertyWithName:(NSString *)propertyName fromClass:(Class)cls {
	return [self setProperty:MTLPropertyFromClass(propertyName, cls)];
}

- (BOOL)setPropertyWithName:(NSString *)propertyName fromProtocol:(Protocol *)protocol {
	return [self setProperty:MTLPropertyFromProtocol(propertyName, protocol)];
}

- (BOOL)setProperty:(objc_property_t)property
{
	if (_property != NULL && _property == property) {
		return YES;
	}
	
	_property = property;
	
	_memoryPolicy = MTLPropertyMemoryPolicyAssign;
	bzero(&_flags, sizeof(_flags));
	_getter = NULL;
	_setter = NULL;
	_name = nil;
	_ivarString = nil;
	_objectClass = Nil;
	
	if (_property == NULL) {
		_typeString = nil;
		return NO;
	}
	
	const char *const propertyName = property_getName(property);
	
	const char *const attrString = property_getAttributes(property);
	if (!attrString) {
		NSAssert(NO, @"Could not get attribute string from property %s.", propertyName);
		return NO;
	}
	
	if (attrString[0] != 'T') {
		NSAssert(NO, @"Expected attribute string \"%s\" for property %s to start with 'T'.", attrString, propertyName);
		return NO;
	}
	
	const char *typeString = attrString + 1;
	const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
	if (!next) {
		NSAssert(NO, @"Could not read past type in attribute string \"%s\" for property %s.", attrString, propertyName);
		return NO;
	}
	
	size_t typeLength = next - typeString;
	if (!typeLength) {
		NSAssert(NO, @"Invalid type in attribute string \"%s\" for property %s.", attrString, propertyName);
		return NO;
	}
	
	// copy the type string
	_typeString = [[NSString alloc] initWithBytesNoCopy:(void *)typeString length:typeLength encoding:NSUTF8StringEncoding freeWhenDone:NO];
	_name = [[NSString alloc] initWithBytesNoCopy:(void *)propertyName length:strlen(propertyName) encoding:NSUTF8StringEncoding freeWhenDone:NO];
	
	// if this is an object type, and immediately followed by a quoted string...
	if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
		// we should be able to extract a class name
		const char *className = typeString + 2;
		next = strchr(className, '"');
		
		if (!next) {
			NSAssert(next, @"Could not read class name in attribute string \"%s\" for property %s.", attrString, propertyName);
			return NO;
		}
		
		if (className != next) {
			size_t classNameLength = next - className;
			char trimmedName[classNameLength + 1];
			
			strncpy(trimmedName, className, classNameLength);
			trimmedName[classNameLength] = '\0';
			
			// attempt to look up the class in the runtime
			_objectClass = objc_getClass(trimmedName);
		}
	}
	
	if (*next != '\0') {
		// skip past any junk before the first flag
		next = strchr(next, ',');
	}
	
	while (next && *next == ',') {
		char flag = next[1];
		next += 2;
		
		switch (flag) {
			case '\0':
				break;
				
			case 'R':
				_flags.readonly = YES;
				break;
				
			case 'C':
				_memoryPolicy = MTLPropertyMemoryPolicyCopy;
				break;
				
			case '&':
				_memoryPolicy = MTLPropertyMemoryPolicyRetain;
				break;
				
			case 'N':
				_flags.nonatomic = YES;
				break;
				
			case 'G':
			case 'S':
			{
				const char *nextFlag = strchr(next, ',');
				SEL name = NULL;
				
				if (!nextFlag) {
					// assume that the rest of the string is the selector
					const char *selectorString = next;
					next = "";
					
					name = sel_registerName(selectorString);
				} else {
					size_t selectorLength = nextFlag - next;
					
					if (!selectorLength) {
						NSAssert(NO, @"Found zero length selector name in attribute string \"%s\" for property %s.", attrString, propertyName);
						return NO;
					}
					
					char selectorString[selectorLength + 1];
					
					strncpy(selectorString, next, selectorLength);
					selectorString[selectorLength] = '\0';
					
					name = sel_registerName(selectorString);
					next = nextFlag;
				}
				
				if (flag == 'G')
					_getter = name;
				else
					_setter = name;
				
				break;
			}
				
			case 'D':
				_flags.dynamic = YES;
				break;
				
			case 'V':
				// assume that the rest of the string (if present) is the ivar name
				// otherwise assume it is dynamic
				if (*next != '\0') {
					_ivarString = [[NSString alloc] initWithBytesNoCopy:(void *)next length:strlen(next) encoding:NSUTF8StringEncoding freeWhenDone:NO];
					next = "";
				}
				
				break;
				
			case 'W':
				_memoryPolicy = MTLPropertyMemoryPolicyWeak;
				break;
				
			case 'P':
				_flags.canBeCollected = YES;
				break;
				
			case 't':
				NSAssert(NO, @"Old-style type encoding is unsupported in attribute string \"%s\" for property %s.", attrString, propertyName);
				
				// skip over this type encoding
				while (*next != ',' && *next != '\0')
					++next;
				
				break;
				
			default:
				NSAssert(NO, @"Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s.", flag, attrString, propertyName);
				break;
		}
	}
	
	if (next && *next != '\0') {
		NSLog(@"Unparsed data \"%s\" in attribute string \"%s\" for property %s.", next, attrString, propertyName);
	}
	
	if (!_getter) {
		// use the property name as the getter by default
		_getter = sel_registerName(propertyName);
	}
	
	if (!_setter && !_flags.readonly) {
		// use the property name to create a set<Foo>: setter
		_setter = MTLSelectorWithCapitalizedKeyPattern("set", propertyName, ":");
	}
	
	return YES;
}

- (const char *)type
{
	return self.typeString.UTF8String;
}

- (const char *)ivar
{
	if (self.dynamic) return NULL;
	return self.ivarString.UTF8String;
}

- (BOOL)isReadonly
{
	return _flags.readonly;
}

- (BOOL)isNonatomic
{
	return _flags.nonatomic;
}

- (BOOL)canBeCollected
{
	return _flags.canBeCollected;
}

- (BOOL)isDynamic
{
	return _flags.dynamic;
}

@end
