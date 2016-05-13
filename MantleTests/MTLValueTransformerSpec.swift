//
//  MTLValueTransformerSpec.swift
//  Mantle
//
//  Created by Zachary Waldowski on 3/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Quick
import Nimble
import Mantle

class MTLValueTransformerSwiftSpec: QuickSpec {
	override func spec() {
		describe("a forward transformer") {
			let transformer = MTLValueTransformer<String, String> {
				"\($0)bar"
			}

			expect(transformer.dynamicType.allowsReverseTransformation()).to(beFalsy())

			it("should support successful ObjC transformation") {
				expect { transformer.transformedValue("foo") as? String } == "foobar"
				expect { transformer.transformedValue("bar") as? String } == "barbar"
			}

			it("should support pure Swift transformation") {
				expect { try transformer.transform("foo") } == "foobar"
				expect { try transformer.transform("bar") } == "barbar"
			}
		}

		describe("a reversible transformer") {
			let transformer = MTLReversibleValueTransformer<String, String>(forward: {
				"\($0)bar"
			}, reverse: {
				String($0.characters.dropLast(3))
			})

			expect(transformer.dynamicType.allowsReverseTransformation()).to(beTruthy())

			it("should support successful ObjC transformation") {
				expect { transformer.transformedValue("foo") as? String } == "foobar"
				expect { transformer.reverseTransformedValue("foobar") as? String } == "foo"
			}

			it("should support pure Swift transformation") {
				expect { try transformer.transform("foo") } == "foobar"
				expect { try transformer.reverseTransform("foobar") } == "foo"
			}
		}

		enum TestError: ErrorType {
			case Something
		}

		it("should support throwing errors") {
			let transformer = MTLValueTransformer<String, String> { _ in
				throw TestError.Something
			}

			expect { try transformer.transform("foo") }.to(throwError(errorType: TestError.self))
		}

		expect(true).to(beTruthy())
	}
}
