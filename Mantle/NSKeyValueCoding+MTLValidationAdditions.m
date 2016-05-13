//
//  NSKeyValueCoding+MTLValidationAdditions.m
//  Mantle
//
//  Created by Zachary Waldowski on 5/10/16.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSKeyValueCoding+MTLValidationAdditions.h"
#import "MTLReflection.h"
#import "NSError+MTLModelException.h"

BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error) {
	// Mark this as being autoreleased, because validateValue may return
	// a new object to be stored in this variable (and we don't want ARC to
	// double-free or leak the old or new values).
	__autoreleasing id validatedValue = value;

	@try {
		if (![obj validateValue:&validatedValue forKey:key error:error]) return NO;

		if (forceUpdate || value != validatedValue) {
			[obj setValue:validatedValue forKey:key];
		}

		return YES;
	} @catch (NSException *ex) {
		NSLog(@"*** Caught exception setting key \"%@\" : %@", key, ex);

		// Fail fast in Debug builds.
		if (MTLIsDebugging()) {
			@throw ex;
		} else if (error != NULL) {
			*error = [[NSError alloc] mtl_initWithModelException:ex localizedDescription:nil];
		}

		return NO;
	}
}
