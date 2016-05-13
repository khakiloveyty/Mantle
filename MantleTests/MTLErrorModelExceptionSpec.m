//
//  MTLErrorModelExceptionSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

#import "NSError+MTLModelException.h"

QuickSpecBegin(MTLErrorModelException)

describe(@"-mtl_initWithModelException:localizedDescription:", ^{
	NSException *exception = [NSException exceptionWithName:@"MTLTestException" reason:@"Just Testing" userInfo:nil];

	it(@"should return a new error for that exception", ^{
		NSError *error = [[NSError alloc] mtl_initWithModelException:exception localizedDescription:nil];

		expect(error).notTo(beNil());
		expect(error.localizedDescription).to(equal(@"Just Testing"));
		expect(error.localizedFailureReason).to(equal(@"Just Testing"));
	});

	it(@"should adopt the given description", ^{
		NSError *error = [[NSError alloc] mtl_initWithModelException:exception localizedDescription:@"A test is being run."];

		expect(error).notTo(beNil());
		expect(error.localizedDescription).to(equal(@"A test is being run."));
		expect(error.localizedRecoverySuggestion).to(equal(@"Just Testing"));
		expect(error.localizedFailureReason).to(equal(@"Just Testing"));
	});
});

QuickSpecEnd
