//
//  FormattableTextFieldSnapshotTests.swift
//  FormattableTextViewSnapshotTests
//
//  Created by Mikhail Motyzhenkov on 31.01.2022.
//  Copyright © 2022 Михаил Мотыженков. All rights reserved.
//

import SnapshotTesting
import FormattableTextView
import XCTest

class FormattableTextFieldSnapshotTests: XCTestCase {

	func testLeftOnlyFormat() throws {
		let field = field(type: .field)
		field.maskAppearance = .leftOnly
		field.formats = ["ddd-ddd"]
		field.text = "123456"
		assert(field)
	}
	
	func testWholeFormat() throws {
		let field = field(type: .field)
		field.maskAppearance = .whole(placeholders: ["d": "0"])
		var attributes = field.inputAttributes
		attributes[.font] = UIFont(name: "Menlo", size: 16)
		field.inputAttributes = attributes
		var maskAttributes = attributes
		maskAttributes[.foregroundColor] = UIColor.lightGray
		field.maskAttributes = maskAttributes
		field.formats = ["ddd-ddd"]
		field.text = "1234"
		assert(field)
	}
	
	func testCurrencySymbol() throws {
		let field = field(type: .field)
		field.maskAppearance = .leftOnly
		field.formats = ["ddddddddd ₽"]
		field.text = "123"
		assert(field)
	}
	
	func testFieldPhoneNumber() throws {
		let field = field(type: .field)
		field.maskAppearance = .leftAndRight
		field.formats = ["+7 (ddd) ddd-dd-dd"]
		field.text = "123"
		assert(field)
	}
}
