//
//  MTLJSONAdapterTransformers.swift
//  Mantle
//
//  Created by Zachary Waldowski on 1/28/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

public enum MTLValueTransformerError: ErrorType, CustomStringConvertible {
	/// Transformers conforming to `MTLTransformerErrorHandling` are expected to
	/// use this error if the transformation fails due to an invalid input value.
	case InvalidInput(AnyObject)

	/// Transformers conforming to `MTLTransformerErrorHandling` are expected to
	/// use this error if the transformation produces a value of an unexpected
	/// type.
	case UnexpectedOutput(Any.Type, expected: Any.Type)

	/// Transforms which compose some mapping over a collection may use this
	/// error if their transform fails due to an individual transformation's
	/// error.
	case TransformError(ErrorType, offset: Int)

	/// Transforms which which don't have a defined set of errors, but can
	/// describe problems that occur may use this error.
	case FormatError(String)

	public var description: String {
		switch self {
		case .InvalidInput(let object):
			return "Could not convert \(object) to model object"
		case let .UnexpectedOutput(got, expected):
			return "Expected an \(expected) as output, got: \(got)."
		case let .TransformError(error, offset):
			return "Could not transform value at index \(offset): \(error)"
		case let .FormatError(text):
			return text
		}
	}
}

extension MTLJSONAdapter {

	/// Creates a reversible transformer to convert a JSON dictionary into a
	/// Mantle model object, and vice-versa.
	public static func dictionaryTransformer() -> MTLReversibleValueTransformer<[String: AnyObject], Model> {
		let adapter = MTLJSONAdapter<Model>()
		return .init(forward: adapter.modelFromJSON, reverse: adapter.JSONFromModel)
	}

	/// Creates a reversible transformer to convert an array of JSON
	/// dictionaries into an array of Mantle model objects, and vice-versa.
	public static func arrayTransformer() -> MTLReversibleValueTransformer<[[String: AnyObject]], [Model]> {
		let adapter = MTLJSONAdapter<Model>()
		return .init(forward: { dictionaries in
			try dictionaries.map(adapter.modelFromJSON)
		}, reverse: { models in
			try models.map(adapter.JSONFromModel)
		})
	}

	/// Creates a reversible transformer to convert NSURL values to JSON
	/// strings and vice versa.
	public static func URLTransformer() -> MTLReversibleValueTransformer<String, NSURL> {
		return .init(forward: { input in
			guard let URL = NSURL(string: input) else {
				throw MTLValueTransformerError.InvalidInput(input)
			}
			return URL
		}, reverse: { $0.absoluteString })
	}

}
