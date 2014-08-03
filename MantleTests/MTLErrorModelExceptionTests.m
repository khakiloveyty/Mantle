//
//  MTLErrorModelExceptionTests.m
//  Mantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"

@interface MTLErrorModelExceptionTests : XCTestCase
@end

@implementation MTLErrorModelExceptionTests

- (void)testErrorForException
{
    NSException *exception = [NSException exceptionWithName:@"MTLTestException" reason:@"Just Testing" userInfo:nil];

	NSError *error = [NSError mtl_modelErrorWithException:exception];

	XCTAssertNotNil(error, @"Should return a new error for that exception");
	XCTAssertEqualObjects(error.localizedDescription, @"Just Testing");
	XCTAssertEqualObjects(error.localizedFailureReason, @"Just Testing");
}

@end
