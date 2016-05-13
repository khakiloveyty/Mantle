//
//  MTLModel+MTLMappingAdditions.swift
//  Mantle
//
//  Created by Zachary Waldowski on 1/21/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

extension MTLModelProtocol {

	/// Creates an identity mapping for serialization.
	///
	/// - returns: A dictionary that maps all properties of `self` to themselves.
	public static func identityPropertyKeyPaths() -> [String: JSONKey] {
		var dictionary = [String: JSONKey]()
		for key in propertyKeys() {
			dictionary[key] = .Path(key)
		}
		return dictionary
	}

}
