//
//  Dictionary+MTLManipulationAdditions.swift
//  Mantle
//
//  Created by Zachary Waldowski on 1/21/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

extension Dictionary {

	/// Merges the keys and values from `pairs`. If both the recieving and the
	/// given dictionaries have a given key, the one from `pairs` is used.
	public func appendingPairs<Sequence: SequenceType where Sequence.Generator.Element == Generator.Element>(pairs: Sequence) -> [Key: Value] {
		var ret = self
		for (key, value) in pairs {
			ret[key] = value
		}
		return ret
	}

	/// Removes `keys`. If a key is not included in the recieving dictionary,
	/// it is not removed.
	public func removingKeys<Sequence: SequenceType where Sequence.Generator.Element == Key>(keys: Sequence) -> [Key: Value] {
		var ret = self
		for key in keys {
			ret.removeValueForKey(key)
		}
		return ret
	}

}
