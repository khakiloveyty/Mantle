//
//  MTLPredefinedTransformerAdditionsSpec.swift
//  Mantle
//
//  Created by Zachary Waldowski on 3/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mantle

let MTLTransformerErrorSwiftExamples = "MTLTransformerErrorSwiftExamples"
let MTLTransformerErrorSwiftExamplesTransformer = "MTLTransformerErrorExamplesTransformer"
let MTLTransformerErrorSwiftExamplesInvalidTransformationInput = "MTLTransformerErrorExamplesInvalidTransformationInput"
let MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput = "MTLTransformerErrorExamplesInvalidReverseTransformationInput"

class MTLTransformerErrorSwiftExamplesConfiguration: QuickConfiguration {

	override class func configure(configuration: Configuration) {
		sharedExamples(MTLTransformerErrorSwiftExamples) { (context: SharedExampleContext) in
			it("should return errors occurring during transformation") {
				guard let transformer = context()[MTLTransformerErrorSwiftExamplesTransformer] as? MTLTransformerErrorHandling,
					invalidInput = context()[MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput] else { return }

				var error: NSError?
				var success: ObjCBool = false
				expect(transformer.transformedValue(invalidInput, success: &success, error: &error)).to(beNil())
				expect(success).to(beFalsy())
				expect(error).notTo(beNil())
			}

			it("should return errors occurring during reverse transformation") {
				guard let transformer = context()[MTLTransformerErrorSwiftExamplesTransformer] as? MTLTransformerErrorHandling,
					invalidInput = context()[MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput],
				    nsTransformer = transformer as? NSValueTransformer
					where nsTransformer.dynamicType.allowsReverseTransformation() else { return }

				var error: NSError?
				var success: ObjCBool = false
				expect(transformer.reverseTransformedValue!(invalidInput, success: &success, error: &error)).to(beNil())
				expect(success).to(beFalsy())
				expect(error).notTo(beNil())
			}
		}
	}

}

class MTLPredefinedTransformerAdditionsSwiftSpec: QuickSpec {
	override func spec() {
		describe("The array-mapping transformer") {
			let URLStrings = [
				"https://github.com/",
				"https://github.com/MantleFramework",
				"http://apple.com"
			]

			let URLs = [
				NSURL(string: "https://github.com/")!,
				NSURL(string: "https://github.com/MantleFramework")!,
				NSURL(string: "http://apple.com")!
			]

			describe("when called with a reversible transformer") {
				var transformer: MTLReversibleValueTransformer<[String], [NSURL]>!
				beforeEach {
					let URLTransformer = MTLReversibleValueTransformer<String, NSURL>(forward: { input in
						guard let URL = NSURL(string: input) else {
							throw MTLValueTransformerError.InvalidInput(input)
						}
						return URL
					}, reverse: { $0.absoluteString })
					transformer = MTLReversibleValueTransformer<[String], [NSURL]>(mappingTransformer: URLTransformer)
				}

				it("should allow reverse transformation") {
					expect(transformer!.dynamicType.allowsReverseTransformation()).to(beTruthy())
				}

				it("should apply the transformer to each element") {
					expect { try transformer.transform(URLStrings) } == URLs
				}

				it("should apply the transformer to each element in reverse") {
					expect { try transformer.reverseTransform(URLs) } == URLStrings
				}

				itBehavesLike(MTLTransformerErrorSwiftExamples) { [
					MTLTransformerErrorSwiftExamplesTransformer: transformer,
					MTLTransformerErrorSwiftExamplesInvalidTransformationInput: NSNull(),
					MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput: NSNull()
				] }
			}

			describe("when called with a forward transformer") {
				var transformer: MTLValueTransformer<[String], [NSURL]>!
				beforeEach {
					let URLTransformer = MTLValueTransformer<String, NSURL> { input in
						guard let URL = NSURL(string: input) else {
							throw MTLValueTransformerError.InvalidInput(input)
						}
						return URL
					}
					transformer = MTLValueTransformer<[String], [NSURL]>(mappingTransformer: URLTransformer)

					expect(transformer!.dynamicType.allowsReverseTransformation()).to(beFalsy())
				}

				itBehavesLike(MTLTransformerErrorSwiftExamples) { [
					MTLTransformerErrorSwiftExamplesTransformer: transformer,
					MTLTransformerErrorSwiftExamplesInvalidTransformationInput: NSNull(),
					MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput: NSNull()
				] }
			}
		}

		describe("value mapping transformer") {
			enum Enum: Int {
				case Negative = -1
				case Zero = 0
				case Positive = 1
				case Default = 42
			}

			var transformer: MTLReversibleValueTransformer<String, Enum>!
			beforeEach {
				transformer = MTLReversibleValueTransformer(valueMapping: [
					"negative": Enum.Negative,
					"zero": Enum.Zero,
					"positive": Enum.Positive
				], defaultValue: Enum.Default, reverseDefaultValue: "default")
			}

			it("should transform enum values into strings") {
				expect { try transformer.transform("negative") } == Enum.Negative
				expect { try transformer.transform("zero") } == Enum.Zero
				expect { try transformer.transform("positive") } == Enum.Positive
			}

			it("should transform strings into enum values") {
				expect(transformer!.dynamicType.allowsReverseTransformation()).to(beTruthy())

				expect { try transformer.reverseTransform(Enum.Negative) } == "negative"
				expect { try transformer.reverseTransform(Enum.Zero) } == "zero"
				expect { try transformer.reverseTransform(Enum.Positive) } == "positive"
			}

			describe("default values") {
				it("should transform unknown strings into the default enum value") {
					expect { try transformer.transform("unknown") } == Enum.Default
				}

				it("should transform the default enum value into the default string") {
					expect { try transformer.reverseTransform(Enum.Default) } == "default"
				}
			}
		}

		describe("date format transformer") {
			var transformer: MTLReversibleValueTransformer<String, NSDate>!
			beforeEach {
				transformer = MTLReversibleValueTransformer(dateFormat: "MMMM d, yyyy", calendar: NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian), locale: NSLocale(localeIdentifier: "en_US"), timeZone: NSTimeZone(name: "America/Los_Angeles"))
			}

			it("should transform strings into dates") {
				expect { try transformer.transform("September 25, 2015") } == NSDate(timeIntervalSince1970: 1443164400)
			}

			it("should transform dates into strings") {
				expect(transformer!.dynamicType.allowsReverseTransformation()).to(beTruthy())

				expect { try transformer.reverseTransform(NSDate(timeIntervalSince1970: 1183135260)) } == "June 29, 2007"
			}

			it("should surface date formatter error descriptions") {
				expect { try transformer.transform("September 37, 2015") }.to(throwError(MTLValueTransformerError.FormatError("The value \"September 37, 2015\" is invalid.")))
			}

			itBehavesLike(MTLTransformerErrorSwiftExamples) { [
				MTLTransformerErrorSwiftExamplesTransformer: transformer,
				MTLTransformerErrorSwiftExamplesInvalidTransformationInput: NSNull(),
				MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput: NSNull()
			] }
		}

		describe("number format transformer") {
			var transformer: MTLReversibleValueTransformer<String, NSNumber>!
			beforeEach {
				transformer = MTLReversibleValueTransformer(numberStyle: .DecimalStyle, locale: NSLocale(localeIdentifier: "en_US"))
			}

			it("should transform strings into numbers") {
				expect { try transformer.transform("0.12345") }.to(beCloseTo(0.12345, within: DBL_EPSILON))
			}

			it("should transform numbers into strings") {
				expect(transformer!.dynamicType.allowsReverseTransformation()).to(beTruthy())

				expect { try transformer.reverseTransform(12345.678) } == "12,345.678"
			}

			it("should surface number formatter error descriptions") {
				expect { try transformer.transform("Apple") }.to(throwError(MTLValueTransformerError.FormatError("The value \"Apple\" is invalid.")))
			}

			itBehavesLike(MTLTransformerErrorSwiftExamples) { [
				MTLTransformerErrorSwiftExamplesTransformer: transformer,
				MTLTransformerErrorSwiftExamplesInvalidTransformationInput: NSNull(),
				MTLTransformerErrorSwiftExamplesInvalidReverseTransformationInput: NSNull()
			] }
		}
	}
}
