//
//  MTLModelMappingSpec.swift
//  Mantle
//
//  Created by Zachary Waldowski on 3/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Quick
import Nimble
import Mantle

class MTLModelMappingSpec: QuickSpec {
	override func spec() {
		it("should return a mapping") {
			let mapping: [String: JSONKey] = [
				"name": "name",
				"count": "count",
				"nestedName": "nestedName",
				"weakModel": "weakModel"
			]

			expect(MTLTestModel.identityPropertyKeyPaths()).to(equal(mapping))
		}
	}
}
