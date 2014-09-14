//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "MTLValueTransformer.h"
#import "MTLModel.h"

@implementation NSValueTransformer (MTLPredefinedTransformerAdditions)

#pragma mark Customizable Transformers

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_arrayMappingTransformerWithTransformer:(NSValueTransformer *)transformer {
	NSParameterAssert(transformer != nil);
	
	id (^forwardBlock)(NSArray *, BOOL *, NSError **) = ^ id (NSArray *values, BOOL *success, NSError **error) {
        if (values == nil){
            return nil;
        }
		
		if (![values isKindOfClass:NSArray.class]) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform non-array type", @""),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), values],
					MTLTransformerErrorHandlingInputValueErrorKey: values
				};
				
				*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
			}
			*success = NO;
			return nil;
		}
		
		__block NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
        [values enumerateObjectsUsingBlock:^(id value, NSUInteger index, BOOL *stop) {
            if (value == NSNull.null) {
                [transformedValues addObject:NSNull.null];
                return;
            }
            
            id transformedValue = nil;
            if ([transformer conformsToProtocol:@protocol(MTLTransformerErrorHandling)]) {
                NSError *underlyingError = nil;
                transformedValue = [(id<MTLTransformerErrorHandling>)transformer transformedValue:value success:success error:&underlyingError];
                
                if (!*success) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                            NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform array", @""),
                            NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Could not transform value at index %ld", @""), (long)index],
                            NSUnderlyingErrorKey: underlyingError,
                            MTLTransformerErrorHandlingInputValueErrorKey: values
                        };
                        
                        *error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    
                    transformedValues = nil;
                    *stop = YES;
                    return;
                }
            } else {
                transformedValue = [transformer transformedValue:value];
            }
            
            if (transformedValue == nil) return;
            
            [transformedValues addObject:transformedValue];
        }];
        
        return transformedValues;
	};
    
    if (!transformer.class.allowsReverseTransformation) {
        return [MTLValueTransformer transformerUsingForwardBlock:forwardBlock];
    }
	
	return [MTLValueTransformer transformerUsingForwardBlock:forwardBlock reverseBlock:^ id (NSArray *values, BOOL *success, NSError **error) {
        if (values == nil) return nil;
        
        if (![values isKindOfClass:NSArray.class]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform non-array type", @""),
                    NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), values],
                    MTLTransformerErrorHandlingInputValueErrorKey: values
                };

                *error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        __block NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
        [values enumerateObjectsUsingBlock:^(id value, NSUInteger index, BOOL *stop) {
            if (value == NSNull.null) {
                [transformedValues addObject:NSNull.null];
                return;
            }
            
            id transformedValue = nil;
            if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
                NSError *underlyingError = nil;
                transformedValue = [(id<MTLTransformerErrorHandling>)transformer reverseTransformedValue:value success:success error:&underlyingError];
                
                if (*success == NO) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform array", @""),
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Could not transform value at index %ld", @""), (long)index],
                                                   NSUnderlyingErrorKey: underlyingError,
                                                   MTLTransformerErrorHandlingInputValueErrorKey: values
                                                   };
                        
                        *error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    
                    transformedValues = nil;
                    *stop = YES;
                    return;
                }
            } else {
                transformedValue = [transformer reverseTransformedValue:value];
            }
            
            if (transformedValue == nil) return;
            
            [transformedValues addObject:transformedValue];
        }];
        
        return transformedValues;
    }];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)mtl_validatingTransformerForClass:(Class)class {
	NSParameterAssert(class != nil);

	return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError **error) {
        if ([value isKindOfClass:class]) {
            return value;
        }
        
        if (error != NULL) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Value did not match expected type", @""),
                NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1$@ to be of class %2$@", @""), value, class],
                MTLTransformerErrorHandlingInputValueErrorKey : value
            };
            *error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
        }
        *success = NO;
        return nil;
	}];
}

+ (NSValueTransformer *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary defaultValue:(id)defaultValue reverseDefaultValue:(id)reverseDefaultValue {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(dictionary.count == [[NSSet setWithArray:dictionary.allValues] count]);

	return [MTLValueTransformer transformerUsingForwardBlock:^(id <NSCopying> key, BOOL *__unused success, __unused NSError **error) {
        return dictionary[key ?: NSNull.null] ?: defaultValue;
    } reverseBlock:^ id (id value, BOOL *__unused success, __unused NSError **error) {
        __block id result = nil;
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id anObject, BOOL *stop) {
            if ([value isEqual:anObject]) {
                result = key;
                *stop = YES;
            }
        }];

        return result ?: reverseDefaultValue;
    }];
}

@end
