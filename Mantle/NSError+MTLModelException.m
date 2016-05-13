//
//  NSError+MTLModelException.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel.h"

#import "NSError+MTLModelException.h"

// The domain for errors originating from MTLModel.
static NSString * const MTLModelErrorDomain = @"MTLModelErrorDomain";

// An exception was thrown and caught.
static const NSInteger MTLModelErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
NSString * const MTLModelThrownExceptionErrorKey = @"MTLModelThrownException";

@implementation NSError (MTLModelException)

- (instancetype)mtl_initWithModelException:(NSException *)exception localizedDescription:(nullable NSString *)description {
	NSParameterAssert(exception != nil);

	NSMutableDictionary *userInfo = [@{
		NSLocalizedFailureReasonErrorKey: exception.reason,
		MTLModelThrownExceptionErrorKey: exception
	} mutableCopy];

	if (description != nil) {
		userInfo[NSLocalizedDescriptionKey] = description;
		userInfo[NSLocalizedRecoverySuggestionErrorKey] = exception.description;
	} else {
		userInfo[NSLocalizedDescriptionKey] = exception.description;
	}

	return (self = [self initWithDomain:MTLModelErrorDomain code:MTLModelErrorExceptionThrown userInfo:userInfo]);
}

@end
