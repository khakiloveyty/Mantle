//
//  NSDictionary+MTLJSONKeyPath.h
//  Mantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (MTLJSONKeyPath)

/** Looks up the value of a key path in the receiver.
 *
 * outValue    - If not @c NULL, this will be set to the value for the key path,
 *               which may be @c nil.
 * JSONKeyPath - The key path that should be resolved. Every element along this
 *               key path needs to be an instance of NSDictionary for the
 *               resolving to be successful.
 * error       - If not @c NULL, this may be set to an error that occurs during
 *               resolving the value.
 *
 * @return @c YES if no error occurred while resolving the value, else @c NO.
 */
- (BOOL)mtl_getValue:(out id *)outValue forJSONKeyPath:(NSString *)JSONKeyPath error:(out NSError **)error;

@end
