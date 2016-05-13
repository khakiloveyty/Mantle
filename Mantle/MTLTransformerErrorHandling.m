//
//  MTLTransformerErrorHandling.h
//  Mantle
//
//  Created by Robert Böhnke on 10/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTransformerErrorHandling.h"
#import "MTLReflection.h"
#import "NSError+MTLModelException.h"

NSString * const MTLTransformerErrorHandlingErrorDomain = @"MTLTransformerErrorHandlingErrorDomain";

const NSInteger MTLTransformerErrorHandlingErrorInvalidInput = 1;

NSString * const MTLTransformerErrorHandlingInputValueErrorKey = @"MTLTransformerErrorHandlingInputValueErrorKey";

@implementation NSValueTransformer (MTLTransformerErrorHandling)

- (id)transformedValue:(id)value success:(BOOL *)success error:(NSError **)error {
	@try {
		id result = [self transformedValue:value];
		if (success != NULL) {
			*success = YES;
		}
		return result;
	} @catch (NSException *ex) {
		NSLog(@"*** Caught exception %@ from: %@ ", ex, self);

		// Fail fast in Debug builds.
		if (MTLIsDebugging()) {
			@throw ex;
		} else if (error != NULL) {
			*error = [[NSError alloc] mtl_initWithModelException:ex localizedDescription:[NSString stringWithFormat:@"Caught exception from transformer %@", self.class]];
		}

		if (success != NULL) {
			*success = NO;
		}

		return nil;
	}
}

- (id)reverseTransformedValue:(id)value success:(BOOL *)success error:(NSError **)error {
	@try {
		id result = [self reverseTransformedValue:value];
		if (success != NULL) {
			*success = YES;
		}
		return result;
	} @catch (NSException *ex) {
		NSLog(@"*** Caught exception %@ from: %@ ", ex, self);

		// Fail fast in Debug builds.
		if (MTLIsDebugging()) {
			@throw ex;
		} else if (error != NULL) {
			*error = [[NSError alloc] mtl_initWithModelException:ex localizedDescription:[NSString stringWithFormat:@"Caught exception from transformer %@", self.class]];
		}

		if (success != NULL) {
			*success = NO;
		}

		return nil;
	}
}

@end
