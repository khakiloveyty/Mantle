//
//  MTLValueTransformer.swift
//  Mantle
//
//  Created by Zachary Waldowski on 1/21/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

import Mantle.MTLValueTransformer

private func objCApplyTransform<In, Out>(transform: In throws -> Out, value: AnyObject?, success: UnsafeMutablePointer<ObjCBool>, error: NSErrorPointer) -> AnyObject? {
	do {
		if case nil = value { return nil }
		guard let input = value as? In else {
			throw MTLValueTransformerError.InvalidInput(value ?? NSNull())
		}
		return try transform(input) as? AnyObject
	} catch let localError as NSError {
		if (success != nil) { success.memory = false }
		if (error != nil) { error.memory = localError }
		return nil
	}
}

/// A value transformer supporting function-based transformation.
public final class MTLValueTransformer<In, Out>: NSValueTransformer {

	/// The forward transform. May be invoked manually.
	public let transform: In throws -> Out

	/// Creates a forward transformer which transforms values using the given
	/// function. Reverse transformations will not be allowed.
	public init(transform: In throws -> Out) {
		self.transform = transform
		super.init()
	}

	// MARK: - NSValueTransformer

	/// Always `false`.
	/// - seealso: MTLReversibleValueTransformer
	public override class func allowsReverseTransformation() -> Bool {
		return false
	}

	public override class func transformedValueClass() -> AnyClass {
		return NSObject.self
	}

    /// Transforms a value.
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		return objCApplyTransform(transform, value: value, success: nil, error: nil)
	}

	// MARK: - MTLTransformerErrorHandling

    /// Transforms a value, returning any error that occurred.
    ///
    /// - parameter value: The value to transform.
    /// - parameter success: If not NULL, on return will indicate whether the
    ///   whether the transformation was successful.
    /// - parameter error: If not NULL, on return may be set to an error that
    ///   occured while transforming the value.
	/// - returns: The result of the transformation. Users should inspect
    ///   `success` to decide how to proceed with the result.
	public override func transformedValue(value: AnyObject?, success: UnsafeMutablePointer<ObjCBool>, error: NSErrorPointer) -> AnyObject? {
		return objCApplyTransform(transform, value: value, success: success, error: error)
	}

}

/// A value transformer supporting reversible function-based transformation.
public final class MTLReversibleValueTransformer<In, Out>: NSValueTransformer {

	/// The forward transform. May be invoked manually.
	public let transform: In throws -> Out

	/// The reverse transform. May be invoked manually.
	public let reverseTransform: Out throws -> In

	/// Creates a transformer which forward and reverse transforms values using
	/// the given functions.
	public init(forward transform: In throws -> Out, reverse reverseTransform: Out throws -> In) {
		self.transform = transform
		self.reverseTransform = reverseTransform
		super.init()
	}

	// MARK: - NSValueTransformer

	/// Always `true`.
	/// - seealso: MTLValueTransformer
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}

	public override class func transformedValueClass() -> AnyClass {
		return NSObject.self
	}

	/// Transforms a value.
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		return objCApplyTransform(transform, value: value, success: nil, error: nil)
	}

	/// Reverse-transforms a value.
	public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
		return objCApplyTransform(reverseTransform, value: value, success: nil, error: nil)
	}

	// MARK: - MTLTransformerErrorHandling

    /// Transforms a value, returning any error that occurred.
    ///
    /// - parameter value: The value to transform.
    /// - parameter success: If not NULL, on return will indicate whether the
    ///   whether the transformation was successful.
    /// - parameter error: If not NULL, on return may be set to an error that
    ///   occured while transforming the value.
	/// - returns: The result of the transformation. Users should inspect
    ///   `success` to decide how to proceed with the result.
	public override func transformedValue(value: AnyObject?, success: UnsafeMutablePointer<ObjCBool>, error: NSErrorPointer) -> AnyObject? {
		return objCApplyTransform(transform, value: value, success: success, error: error)
	}

	/// Reverse-transforms a value, returning any error that occurred.
	///
    /// - parameter value: The value to transform.
    /// - parameter success: If not NULL, on return will indicate whether the
    ///   whether the transformation was successful.
    /// - parameter error: If not NULL, on return may be set to an error that
    ///   occured while transforming the value.
	/// - returns: The result of the transformation. Users should inspect
    ///   `success` to decide how to proceed with the result.
	public override func reverseTransformedValue(value: AnyObject?, success: UnsafeMutablePointer<ObjCBool>, error: NSErrorPointer) -> AnyObject? {
		return objCApplyTransform(reverseTransform, value: value, success: success, error: error)
	}

}

extension MTLReversibleValueTransformer {

	/// Returns a transformer by flipping the direction of `self`, such that
	/// a forward transformation becomes a reverse transformation, and vice-versa.
	public func inverted() -> MTLReversibleValueTransformer<Out, In> {
		return .init(forward: reverseTransform, reverse: transform)
	}

}
