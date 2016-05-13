//
//  DictionaryManipulationSpec.swift
//  Mantle
//
//  Created by Zachary Waldowski on 3/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Quick
import Nimble
import Mantle

class DictionaryManipulationSpec: QuickSpec {
	override func spec() {
		describe("+") {
			let dict: [NSObject: NSObject] = [ "foo": "bar", 5: NSNull() ]

			it("should return the same dictionary when adding from an empty dictionary") {
				let combined = dict.appendingPairs([:])
				expect(combined) == dict
			}

			it("should add any new keys") {
				let combined = dict.appendingPairs([ "buzz": 10, "baz": NSNull() ])
				let expected = [ "foo": "bar", 5: NSNull(), "buzz": 10, "baz": NSNull() ]
				expect(combined) == expected
			}

			it("should replace any existing keys") {
				let combined = dict.appendingPairs([ 5: 10, "buzz": "baz" ])
				let expected = [ "foo": "bar", 5: 10, "buzz": "baz" ]
				expect(combined) == expected
			}
		}

		describe("byRemoving(_:)") {
			let dict: [NSObject: NSObject] = [ "foo": "bar", 5: NSNull() ]

			it("should return the same dictionary when removing keys that don't exist in the receiver") {
				let removed = dict.removingKeys([])
				expect(removed) == dict
			}

			it("should remove all the entries for the given keys") {
				let removed = dict.removingKeys([ 5 ])
				let expected = [ "foo": "bar" ]
				expect(removed) == expected
			}

			it("should return an empty dictionary when it removes all its keys") {
				let removed = dict.removingKeys(dict.keys)
				expect(removed).to(beEmpty())
			}
		}
	}
}
