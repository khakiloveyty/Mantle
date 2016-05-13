//
//  NSDictionary+MTLMappingAdditions.h
//  Mantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (MTLMappingAdditions)

/// Creates an identity mapping for serialization.
///
/// class - A subclass of MTLModel.
///
/// Returns a dictionary that maps all properties of the given class to
/// themselves.
+ (NSDictionary<NSString *, NSString *> *)mtl_identityPropertyMapWithModel:(Class<MTLModel>)modelClass NS_SWIFT_UNAVAILABLE("Use MTLModelProtocol.Type.identityPropertyKeyPaths()");

@end

NS_ASSUME_NONNULL_END
