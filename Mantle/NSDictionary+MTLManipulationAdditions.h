//
//  NSDictionary+MTLManipulationAdditions.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-24.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<KeyType, ObjectType> (MTLManipulationAdditions)

/// Merges the keys and values from the given dictionary into the receiver. If
/// both the receiver and `dictionary` have a given key, the value from
/// `dictionary` is used.
///
/// Returns a new dictionary containing the entries of the receiver combined with
/// those of `dictionary`.
- (NSDictionary<KeyType, ObjectType> *)mtl_dictionaryByAddingEntriesFromDictionary:(nullable NSDictionary<KeyType, ObjectType> *)dictionary NS_SWIFT_UNAVAILABLE("Use Dictionary.appendingPairs(_:)");

/// Creates a new dictionary with all the entries for the given keys removed from
/// the receiver.
- (NSDictionary<KeyType, ObjectType> *)mtl_dictionaryByRemovingValuesForKeys:(nullable NSArray<KeyType> *)keys NS_SWIFT_UNAVAILABLE("Use Dictionary.removingKeys(_:)");

@end

@interface NSDictionary<KeyType, ObjectType> (MTLManipulationAdditions_Deprecated)

- (NSDictionary<KeyType, ObjectType> *)mtl_dictionaryByRemovingEntriesWithKeys:(NSSet<KeyType> *)keys MANTLE_DEPRECATED("Replaced by -mtl_dictionaryByRemovingValuesForKeys:");

@end

NS_ASSUME_NONNULL_END
