//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.swift
//  Mantle
//
//  Created by Zachary Waldowski on 1/28/16.
//  Copyright © 2016. Some rights reserved. Licensed under MIT.
//

import Foundation

// MARK: - Enum mapping

private func mapValue<In: Hashable, Out>(dictionary: [In: Out], makeDefaultValue: () throws -> Out) -> In throws -> Out {
	return { input in
		try dictionary[input] ?? makeDefaultValue()
	}
}

extension MTLValueTransformer where In: Hashable {

	/// Creates a value transformer from the keys to the values of `dictionary`.
	///
	/// Can, for example, be used to transform between values and string
	/// representations:
	///
	///     let valueTransformer = MTLReversibleValueTransformer(valueMapping: [
	///         "foo": MyObjCDataType.Foo.rawValue,
	///         "bar": MyObjCDataType.Bar.rawValue,
	///     ], defaultValue: MyObjCDataType.Undefined.rawValue)
	///
	/// - parameter dictionary: The dictionary whose keys and values should be
	///  transformed between.
	/// - parameter defaultValue: The result to fall back to in case no key
	/// matching the input was found during a forward transformation.
	public convenience init(valueMapping dictionary: [In: Out], @autoclosure(escaping) defaultValue: () throws -> Out) {
		self.init(transform: mapValue(dictionary, makeDefaultValue: defaultValue))
	}

}

extension MTLReversibleValueTransformer where In: Hashable, Out: Equatable {

	/// Creates a value transformer to between the keys and values of
	/// `dictionary`.
	///
	/// Can, for example, be used to transform between values and string
	/// representations:
	///
	///     let valueTransformer = MTLReversibleValueTransformer(valueMapping: [
	///         "foo": MyObjCDataType.Foo.rawValue,
	///         "bar": MyObjCDataType.Bar.rawValue,
	///     ], defaultValue: MyObjCDataType.Undefined.rawValue, reverseDefaultValue: "undefined")
	///
	/// - parameter dictionary: The dictionary whose keys and values should be
	///  transformed between.
	/// - parameter defaultValue: The result to fall back to in case no key
	/// matching the input was found during a forward transformation.
	/// - parameter reverseDefaultValue: The result to fall back to in case no
	/// value matching the input was found during a reverse transformation.
	public convenience init(valueMapping dictionary: [In: Out], @autoclosure(escaping) defaultValue: () throws -> Out, @autoclosure(escaping) reverseDefaultValue: () throws -> In) {
		self.init(forward: mapValue(dictionary, makeDefaultValue: defaultValue), reverse: {
			for (key, value) in dictionary where value == $0 {
				return key
			}
			return try reverseDefaultValue()
		})
	}

}

extension MTLReversibleValueTransformer where Out: RawRepresentable, In == Out.RawValue {

	/// Create a reversible value transformer to transform between the cases of
	/// an enum backed by a raw value.
	///
	/// - parameter defaultValue: The case to fall back to in case the
	/// input did not match one of the enum's cases.
	public convenience init(@autoclosure(escaping) defaultValue: Void throws -> Out) {
		self.init(forward: {
			try Out(rawValue: $0) ?? defaultValue()
		}, reverse: {
			$0.rawValue
		})
	}

}

// MARK: - Array mapping

private func apply<In: SequenceType, Out: RangeReplaceableCollectionType>(transform: In.Generator.Element throws -> Out.Generator.Element) -> In throws -> Out {
	return { input in
		var offset = 0
		let transformed = try input.map { item -> Out.Generator.Element in
			defer { offset += 1 }
			do {
				return try transform(item)
			} catch {
				throw MTLValueTransformerError.TransformError(error, offset: offset)
			}
		}

		var result = Out()
		result.appendContentsOf(transformed)
		return result
	}
}

extension MTLValueTransformer where In: SequenceType, Out: RangeReplaceableCollectionType {

	/// Creates a transformer which applies `transformer` to each element of a
	/// sequence.
	public convenience init(mappingTransformer transformer: MTLValueTransformer<In.Generator.Element, Out.Generator.Element>) {
		self.init(transform: apply(transformer.transform))
	}

}

extension MTLReversibleValueTransformer where In: RangeReplaceableCollectionType, Out: RangeReplaceableCollectionType {

	/// Creates a reversible transformer which applies `transformer` to each
	/// element of a collection.
	public convenience init(mappingTransformer transformer: MTLReversibleValueTransformer<In.Generator.Element, Out.Generator.Element>) {
		self.init(forward: apply(transformer.transform), reverse: apply(transformer.reverseTransform))
	}

}

// MARK: - NSFormatter

extension MTLReversibleValueTransformer where In: Streamable, In: OutputStreamType, In: StringLiteralConvertible {

	/// Creates a reversible transformer between an object and its string
	/// representation.
	///
	///
	/// - parameter formatter: A class for a formatter to create for reuse.
	/// - parameter type: The expected output type of the formatter.
	/// - parameter configure: A function body used to set up the formatter.
	public convenience init<Formatter: NSFormatter>(formatter: Formatter.Type, of _: Out.Type = Out.self, @noescape configuration configure: Formatter throws -> Void) rethrows {
		let formatter = Formatter()
		try configure(formatter)

		self.init(forward: { input in
			var string = ""
			input.writeTo(&string)

			var object: AnyObject?
			var errorDescription: NSString?
			guard formatter.getObjectValue(&object, forString: string, errorDescription: &errorDescription) else {
				if let errorDescription = errorDescription as? String {
					throw MTLValueTransformerError.FormatError(errorDescription)
				} else {
					throw MTLValueTransformerError.InvalidInput(string)
				}
			}

			guard let result = object as? Out else {
				throw MTLValueTransformerError.UnexpectedOutput(object.dynamicType, expected: Out.self)
			}

			return result
		}, reverse: { (input: Out) throws -> In in
			guard let object = input as? AnyObject else {
				throw MTLValueTransformerError.InvalidInput(NSNull())
			}

			guard let string = formatter.stringForObjectValue(object) else {
				throw MTLValueTransformerError.InvalidInput(object)
			}

			var result = "" as In
			result.write(string)
			return result
		})
	}

}

extension MTLReversibleValueTransformer where In: Streamable, In: OutputStreamType, In: StringLiteralConvertible, Out: NSDate {

	/// Creates a reversible value transformer to transform between a date and
	/// its string representation.
	///
	/// - parameter dateFormat: The date format used by the date formatter
	/// - parameter calendar: The calendar used by the date formatter
	/// - parameter locale: The locale in which to format the value
	/// - parameter timeZone: The time zone used by the date formatter
	/// - parameter defaultDate: The default date used by the date formatter
	/// - seealso: http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Field_Symbol_Table
	public convenience init(dateFormat: String, locale: NSLocale? = nil, calendar: NSCalendar? = nil, timeZone: NSTimeZone? = nil, defaultDate: NSDate? = nil) {
		try! self.init(formatter: NSDateFormatter.self) { dateFormatter in
			dateFormatter.dateFormat = dateFormat
			dateFormatter.calendar = calendar
			dateFormatter.locale = locale
			dateFormatter.timeZone = timeZone
			dateFormatter.defaultDate = defaultDate
		}
	}

}

extension MTLReversibleValueTransformer where In: Streamable, In: OutputStreamType, In: StringLiteralConvertible, Out: NSNumber {

	/// Creates a reversible value transformer to transform between a number and
	/// its string representation.
	///
	/// - parameter numberStyle: The number style used by the number formatter
	public convenience init(numberStyle: NSNumberFormatterStyle, locale: NSLocale? = nil) {
		try! self.init(formatter: NSNumberFormatter.self) { numberFormatter in
			numberFormatter.numberStyle = numberStyle
			numberFormatter.locale = locale
		}
	}

}
