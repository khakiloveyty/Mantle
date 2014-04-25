//
//  MTLJSONAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <objc/runtime.h>

#import "NSDictionary+MTLJSONKeyPath.h"

#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLTransformerErrorHandling.h"
#import "MTLReflection.h"
#import "MTLPropertyAttributes.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "NSDictionary+MTLMappingAdditions.h"

NSString * const MTLJSONAdapterErrorDomain = @"MTLJSONAdapterErrorDomain";
const NSInteger MTLJSONAdapterErrorNoClassFound = 2;
const NSInteger MTLJSONAdapterErrorInvalidJSONDictionary = 3;
const NSInteger MTLJSONAdapterErrorInvalidJSONMapping = 4;

// An exception was thrown and caught.
const NSInteger MTLJSONAdapterErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const MTLJSONAdapterThrownExceptionErrorKey = @"MTLJSONAdapterThrownException";

@interface MTLJSONAdapter ()

// The MTLModel subclass being parsed, or the class of `model` if parsing has
// completed.
@property (nonatomic, strong, readonly) Class modelClass;

// A cached copy of the return value of +JSONKeyPathsByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;

// A cached copy of the return value of -valueTransformersForModelClass:
@property (nonatomic, copy, readonly) NSDictionary *valueTransformersByPropertyKey;

// Used to cache the JSON adapters returned by -JSONAdapterForModelClass:.
@property (nonatomic, strong, readonly) NSMapTable *JSONAdaptersByModelClass;

// If +classForParsingJSONDictionary: returns a model class different from the
// one this adapter was initialized with, use this method to obtain a cached
// instance of a suitable adapter instead.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <MTLJSONSerializing>. This argument must not be nil.
//
// Returns a JSON adapter for modelClass, creating one of necessary.
- (MTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass;

// Collect all value transformers needed for a given class.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <MTLJSONSerializing>. This argument must not be nil.
//
// Returns a dictionary with the properties of modelClass that need
// transformation as keys and the value transformers as values.
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;

@end

@implementation MTLJSONAdapter

#pragma mark Convenience methods

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	MTLJSONAdapter *adapter = [[self alloc] initWithModelClass:modelClass];

	return [adapter modelFromJSONDictionary:JSONDictionary error:error];
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError **)error {
	if (JSONArray == nil || ![JSONArray isKindOfClass:NSArray.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON array", @""),
				NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON array was provided: %@", @""), NSStringFromClass(modelClass), JSONArray.class],
			};
			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}

	NSMutableArray *models = [NSMutableArray arrayWithCapacity:JSONArray.count];
	for (NSDictionary *JSONDictionary in JSONArray){
		MTLModel *model = [self modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];

		if (model == nil) return nil;
		
		[models addObject:model];
	}
	
	return models;
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	MTLJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];

	return [adapter JSONDictionaryFromModel:model error:error];
}

+ (NSArray *)JSONArrayFromModels:(NSArray *)models error:(NSError **)error {
	NSParameterAssert(models != nil);
	NSParameterAssert([models isKindOfClass:NSArray.class]);

	NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:models.count];
	for (MTLModel<MTLJSONSerializing> *model in models) {
		NSDictionary *JSONDictionary = [self JSONDictionaryFromModel:model error:error];
		if (JSONDictionary == nil) return nil;

		[JSONArray addObject:JSONDictionary];
	}

	return JSONArray;
}

#pragma mark Lifecycle

- (id)init {
	NSAssert(NO, @"%@ must be initialized with a model class", self.class);
	return nil;
}

- (id)initWithModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	self = [super init];
	if (self == nil) return nil;

	_modelClass = modelClass;

	_JSONKeyPathsByPropertyKey = [modelClass JSONKeyPathsByPropertyKey];
	_valueTransformersByPropertyKey = [self.class valueTransformersForModelClass:modelClass];

	_JSONAdaptersByModelClass = [NSMapTable strongToStrongObjectsMapTable];

	return self;
}

#pragma mark Serialization

- (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert([model isKindOfClass:self.modelClass]);

	if (self.modelClass != model.class) {
		MTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:model.class];

		return [otherAdapter JSONDictionaryFromModel:model error:error];
	}

	NSSet *propertyKeysToSerialize = [self serializablePropertyKeys:[NSSet setWithArray:self.JSONKeyPathsByPropertyKey.allKeys] forModel:model];

	NSDictionary *dictionaryValue = [model.dictionaryValue dictionaryWithValuesForKeys:propertyKeysToSerialize.allObjects];
	NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];

	__block BOOL success = YES;
	__block NSError *tmpError = nil;

	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];

		if (JSONKeyPaths == nil) return;

		NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
		if ([transformer.class allowsReverseTransformation]) {
			// Map NSNull -> nil for the transformer, and then back for the
			// dictionaryValue we're going to insert into.
			if ([value isEqual:NSNull.null]) value = nil;

			if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
				id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;

				value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];

				if (!success) {
					*stop = YES;
					return;
				}
			} else {
				value = [transformer reverseTransformedValue:value] ?: NSNull.null;
			}
		}

		void (^createComponents)(id, NSString *) = ^(id obj, NSString *keyPath) {
			NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];

			// Set up dictionaries at each step of the key path.
			for (NSString *component in keyPathComponents) {
				if ([obj valueForKey:component] == nil) {
					// Insert an empty mutable dictionary at this spot so that we
					// can set the whole key path afterward.
					[obj setValue:[NSMutableDictionary dictionary] forKey:component];
				}

				obj = [obj valueForKey:component];
			}
		};

		if ([JSONKeyPaths isKindOfClass:NSString.class]) {
			createComponents(JSONDictionary, JSONKeyPaths);

			[JSONDictionary setValue:value forKeyPath:JSONKeyPaths];
		}

		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			for (NSString *JSONKeyPath in JSONKeyPaths) {
				createComponents(JSONDictionary, JSONKeyPath);

				[JSONDictionary setValue:value[JSONKeyPath] forKeyPath:JSONKeyPath];
			}
		}
	}];

	if (success) {
		return JSONDictionary;
	} else {
		if (error != NULL) *error = tmpError;
		return nil;
	}
}

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	Class modelClass = self.modelClass;

	if ([modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
		Class class = [modelClass classForParsingJSONDictionary:JSONDictionary];
		if (class == nil) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @"")
				};

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorNoClassFound userInfo:userInfo];
			}

			return nil;
		}

		if (class != self.modelClass) {
			NSAssert([class conformsToProtocol:@protocol(MTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <MTLJSONSerializing>", class);

			MTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:class];

			return [otherAdapter modelFromJSONDictionary:JSONDictionary error:error];
		}
	}

	NSSet *propertyKeys = [self.modelClass propertyKeys];

	for (NSString *JSONKeyPath in self.JSONKeyPathsByPropertyKey) {
		if ([propertyKeys containsObject:JSONKeyPath]) continue;

		if (error != NULL) {
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON mapping", nil),
									   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%1$@ could not be parsed because its JSON mapping contains illegal property keys.", nil), modelClass]
									   };

			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONMapping userInfo:userInfo];
		}
		
		return nil;
	}

	NSDictionary *dictionaryValue = MTLCopyPropertyKeyMapUsingBlock(modelClass, ^id(NSString *propertyKey, BOOL *stop) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];

		if (JSONKeyPaths == nil) return nil;

		id value;

		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

			for (NSString *keyPath in JSONKeyPaths) {
				if ([JSONDictionary mtl_getObjectValue:&value forJSONKeyPath:keyPath error:error]) {
					if (value != nil) dictionary[keyPath] = value;
				} else {
					*stop = YES;
					return nil;
				}
			}

			value = dictionary;
		} else {
			if (![JSONDictionary mtl_getObjectValue:&value forJSONKeyPath:JSONKeyPaths error:error]) {
				*stop = YES;
				return nil;
			}
		}

		if (value == nil) return nil;

		@try {
			NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;

				if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
					id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;

					BOOL success = YES;
					value = [errorHandlingTransformer transformedValue:value success:&success error:error];

					if (!success) {
						*stop = YES;
						return nil;
					}
				} else {
					value = [transformer transformedValue:value];
				}

				if (value == nil) value = NSNull.null;
			}

			return value;
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPaths, JSONDictionary);

			// Fail fast in Debug builds.
#if DEBUG
			@throw ex;
#else
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: ex.description,
										   NSLocalizedFailureReasonErrorKey: ex.reason,
										   MTLJSONAdapterThrownExceptionErrorKey: ex
										   };

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
			}

			*stop = YES;
			return nil;
#endif
		}
	});

	if (!dictionaryValue) {
		return nil;
	}

	return [[modelClass alloc] initWithDictionary:dictionaryValue error:error];
}

+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	__block MTLPropertyAttributes *reusedAttributes = nil;
	return MTLCopyPropertyKeyMapUsingBlock(modelClass, ^id(NSString *key, BOOL *stop) {
		SEL selector = MTLSelectorWithKeyPattern(NULL, key, "JSONTransformer");
		if ([modelClass respondsToSelector:selector]) {
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[modelClass methodSignatureForSelector:selector]];
			invocation.target = modelClass;
			invocation.selector = selector;
			[invocation invoke];

			__unsafe_unretained id transformer = nil;
			[invocation getReturnValue:&transformer];
			return transformer;
		}

		if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
			return [modelClass JSONTransformerForKey:key];
		}

		MTLPropertyAttributes *attributes = [MTLPropertyAttributes propertyNamed:key class:modelClass reusingAttributes:&reusedAttributes];

		if (attributes == nil) return nil;

		if (*(attributes.type) == *(@encode(id))) {
			Class propertyClass = attributes.objectClass;

			NSValueTransformer *transformer = nil;
			if (propertyClass != nil) {
				transformer = [self transformerForModelPropertiesOfClass:propertyClass];
			}
			return transformer ?: [NSValueTransformer mtl_validatingTransformerForClass:NSObject.class];
		}

		return [self transformerForModelPropertiesOfObjCType:attributes.type] ?: [NSValueTransformer mtl_validatingTransformerForClass:NSValue.class];
	});
}

- (MTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	@synchronized(self) {
		MTLJSONAdapter *result = [self.JSONAdaptersByModelClass objectForKey:modelClass];

		if (result != nil) return result;

		result = [[MTLJSONAdapter alloc] initWithModelClass:modelClass];
		[self.JSONAdaptersByModelClass setObject:result forKey:modelClass];
		return result;
	}
}

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MTLJSONSerializing>)model {
	return propertyKeys;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);

	SEL selector = MTLSelectorWithKeyPattern(NULL, NSStringFromClass(modelClass), "JSONTransformer");
	if (![self respondsToSelector:selector]) return nil;

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	invocation.target = self;
	invocation.selector = selector;
	[invocation invoke];

	__unsafe_unretained id result = nil;
	[invocation getReturnValue:&result];
	return result;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType {
	NSParameterAssert(objCType != NULL);

	if (strcmp(objCType, @encode(BOOL)) == 0) {
		return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
	}

	return nil;
}

@end

@implementation MTLJSONAdapter (ValueTransformers)

+ (NSValueTransformer *)NSURLJSONTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
