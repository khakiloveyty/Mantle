//
//  MTLJSONAdapter.swift
//  Mantle
//
//  Created by Zachary Waldowski on 1/21/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

public enum MTLJSONAdapterError: ErrorType, CustomStringConvertible {
	/// +classForParsingJSONDictionary: returned nil for the given dictionary.
	case NoClassFound

	/// The provided JSONDictionary is not valid.
	case InvalidJSONDictionary

	/// The model's implementation of +JSONKeyPathsByPropertyKey included a key which
	/// does not actually exist in +propertyKeys.
	case InvalidJSONMapping

	/// The `type` does not implement an Objective-C property that is key-value
	/// coding compliant property `key`.
	case UndefinedKey(String, type: MTLJSONSerializing.Type)

	/// An exception was thrown and caught.
	case ExceptionThrown(NSException)

	public var description: String {
		switch self {
		case .NoClassFound:
			return "MTLJSONSerializing.Type.classForParsingJSONDictionary(_:) returned nil for the given dictionary."
		case .InvalidJSONDictionary:
			return "The provided JSON dictionary is not valid."
		case .InvalidJSONMapping:
			return "The model's implementation of MTLModelProtocol.Type.JSONKeyPathsByPropertyKey() included a key which does not actually exist in its property keys."
		case .UndefinedKey(let key, let type):
			return "The class \"\(type)\" is not key value coding-compliant for \"\(key)\"."
		case .ExceptionThrown(let exception):
			return "Caught exception parsing JSON key path: \(exception)"
		}
	}
}

private extension MTLJSONAdapterError {

	init!(jsonError error: NSError) {
		switch error.code {
		case MTLJSONAdapterErrorNoClassFound:
			self = .NoClassFound
		case MTLJSONAdapterErrorInvalidJSONDictionary:
			self = .InvalidJSONDictionary
		case MTLJSONAdapterErrorInvalidJSONMapping:
			self = .InvalidJSONMapping
		case MTLJSONAdapterErrorExceptionThrown:
			let exception = error.userInfo[MTLJSONAdapterThrownExceptionErrorKey] as! NSException
			if exception.name == NSUndefinedKeyException,
				let key = exception.userInfo?["NSUnknownUserInfoKey"] as? String,
				type = exception.userInfo?["NSTargetObjectUserInfoKey"]?.dynamicType as? MTLJSONSerializing.Type {
				self = .UndefinedKey(key, type: type)
			} else {
				self = .ExceptionThrown(exception)
			}
		default:
			return nil
		}
	}

	init!(modelError error: NSError) {
		switch error.code {
		case 1:
			let exception = error.userInfo[__MTLModelThrownExceptionErrorKey] as! NSException
			self = .ExceptionThrown(exception)
		default:
			return nil
		}
	}

}

private func bridgeFromObjCError<T>(@autoclosure body: () throws -> T) throws -> T {
	do {
		return try body()
	} catch let error as NSError where error.domain == MTLJSONAdapterErrorDomain {
		throw MTLJSONAdapterError(jsonError: error)
	} catch let error as NSError where error.domain == "MTLModelErrorDomain" {
		throw MTLJSONAdapterError(modelError: error)
	}
}

public enum JSONKey {
	case Path(String)
	case Composite([String])
}

public protocol MTLJSONSerializing: __MTLJSONSerializing {

	static var JSONKeyPaths: [String : JSONKey] { get }

}

public func ==(lhs: JSONKey, rhs: JSONKey) -> Bool {
	switch (lhs, rhs) {
	case let (.Path(lhsString), .Path(rhsString)):
		return lhsString == rhsString
	case let (.Composite(lhsArray), .Composite(rhsArray)):
		return lhsArray == rhsArray
	default:
		return false
	}
}

extension JSONKey: Equatable, StringLiteralConvertible, ArrayLiteralConvertible {

	public init(unicodeScalarLiteral value: String) {
		self = .Path(value)
	}

	public init(extendedGraphemeClusterLiteral value: String) {
		self = .Path(value)
	}

	public init(stringLiteral value: String) {
		self = .Path(value)
	}

	public init(arrayLiteral elements: String...) {
		self = .Composite(elements)
	}

}

private extension JSONKey {

	var objectValue: AnyObject {
		switch self {
		case .Path(let string):
			return string
		case .Composite(let strings):
			return strings
		}
	}

}

private final class JSONKeyPathDictionary: NSDictionary {

	var underlying: [String: JSONKey]!

	convenience init(_ underlying: [String: JSONKey]) {
		self.init()
		self.underlying = underlying
	}

	override var count: Int {
		return underlying.count
	}

	override func keyEnumerator() -> NSEnumerator {
		return (Array(underlying.keys) as NSArray).objectEnumerator()
	}

	override func objectForKey(aKey: AnyObject) -> AnyObject? {
		return underlying[aKey as! String]?.objectValue
	}

}

public class MTLJSONAdapter<Model: MTLJSONSerializing>: __MTLJSONAdapter {

	/// Attempts to parse a JSON dictionary into a model object.
	///
	/// - parameter JSONDictionary: A dictionary representing JSON data. This
	///   should match the format returned by `NSJSONSerialization`.
	/// - parameter modelType: The model class to attempt to parse from the
	///   JSON.
	/// - throws: `MTLJSONAdapterError` for serialization errors, or any errors
	///   thrown by `Model.validate()`
	public class func modelFromJSON(JSONDictionary: [String: AnyObject], ofType modelType: Model.Type = Model.self) throws -> Model {
		return try bridgeFromObjCError(__modelOfClass(modelType, fromJSONDictionary: JSONDictionary) as! Model)
	}

	/// Attempts to parse an array of JSON dictionary objects into a model
	/// objects.
	///
	/// - parameter JSONArray: An array of dictionaries representing JSON data.
	///   This should match the format returned by `NSJSONSerialization`.
	/// - parameter modelType: The model class to attempt to parse from the
	///   JSON.
	/// - throws: `MTLJSONAdapterError` for serialization errors, or any errors
	///   thrown by `Model.validate()`
	public static func modelsFromJSON(JSONArray: [[String: AnyObject]], ofType modelType: Model.Type = Model.self) throws -> [Model] {
		return try bridgeFromObjCError(__modelsOfClass(modelType, fromJSONArray: JSONArray) as! [Model])
	}

	/// Converts a model into a JSON representation.
	///
	/// - parameter model: The model to use for JSON serialization.
	/// - throws: `MTLJSONAdapterError`
	public static func JSONFromModel(model: Model) throws -> [String: AnyObject] {
		return try bridgeFromObjCError(__JSONDictionaryFromModel(model))
	}

	/// Converts a array of models into a JSON representation.
	///
	/// - parameter models: The array of models to use for JSON serialization.
	/// - throws: `MTLJSONAdapterError`
	public static func JSONFromModels(models: [Model]) throws -> [[String: AnyObject]] {
		return try bridgeFromObjCError(__JSONArrayFromModels(models))
	}

	// Inherited initializer isn't being deleted, strangely.
	private override init(__modelClass modelClass: AnyClass, _opaque_JSONKeyPathsByPropertyKey JSONKeyPathsByPropertyKey: AnyObject) {
		fatalError("Not supported")
	}

	/// Creates an initialized adapter.
	@objc(_swiftInitWithGenericClass)
	public init() {
		super.init(__modelClass: Model.self, _opaque_JSONKeyPathsByPropertyKey: JSONKeyPathDictionary(Model.JSONKeyPaths))
	}

    /// Deserializes a model from a JSON dictionary.
    ///
	/// - parameter JSONDictionary: A dictionary representing JSON data. This
	///   should match the format returned by `NSJSONSerialization`.
	/// - throws: `MTLJSONAdapterError` for serialization errors, or any errors
	///   thrown by `Model.validate()`
	public func modelFromJSON(JSONDictionary: [String : AnyObject]) throws -> Model {
		return try bridgeFromObjCError(__modelFromJSONDictionary(JSONDictionary) as! Model)
	}

	/// Serializes a model into JSON.
	///
	/// - parameter model: The model to use for JSON serialization.
	/// - throws: `MTLJSONAdapterError`
	public func JSONFromModel(model: Model) throws -> [String : AnyObject] {
		return try bridgeFromObjCError(__JSONDictionaryFromModel(model))
	}

    override public final func __serializablePropertyKeys(propertyKeys: Set<String>, forModel model: __MTLJSONSerializing) -> Set<String> {
        return serializablePropertyKeys(propertyKeys, forModel: model as! Model)
    }

    /// Filters the property keys used to serialize the model.
    ///
    /// Subclasses may override this method to determine which property keys
    /// should be used when serializing `model`. For instance, an override may
    /// be used to create more efficient updates of server-side resources.
    ///
    /// The default implementation simply returns `propertyKeys`.
    ///
    /// - parameter propertyKeys: The property keys for which `model` provides
    ///   a mapping.
    /// - parameter model: The model being serialized.
    /// - returns: A subset of `propertyKeys` that should be serialized for a
    ///   given model.
    public func serializablePropertyKeys(propertyKeys: Set<String>, forModel model: Model) -> Set<String> {
        return propertyKeys
    }

}
