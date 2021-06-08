//
//  FormattableTextTests.swift
//  FormattableTextViewTests
//
//  Created by Mikhail Motyzhenkov on 21.05.2021.
//  Copyright © 2021 Михаил Мотыженков. All rights reserved.
//

import XCTest
import FormattableTextView

class FormattableTextTests: XCTestCase {
	
	func testDashInTextView() throws {
		let tv = FormattableKernTextView()
		tv.formats = ["ddd-ddd"]
		tv.text = "123456"
		
		let result = tv.formattedText
		XCTAssertEqual(result, "123-456")
	}
	
	func testDashInTextField() throws {
		let tv = FormattableTextField()
		tv.formats = ["ddd-ddd"]
		tv.text = "123456"
		
		let result = tv.formattedText
		XCTAssertEqual(result, "123-456")
	}
	
	func testLongFormatLeftOnly() throws {
		let tv = FormattableKernTextView()
		tv.formats = ["w*45d-_*asdf"]
		tv.text = "t(9"
		
		let result = tv.formattedText
		XCTAssertEqual(result, "t(459")
	}
	
	func testLongFormatLeftAndRight() throws {
		let tv = FormattableKernTextView()
		tv.formats = ["w*45d-_*asdf"]
		tv.text = "t(9"
		tv.maskAppearance = .leftAndRight
		
		let result = tv.formattedText
		XCTAssertEqual(result, "t(459-_")
	}
	
	func testLongFormatWhole() throws {
		let tv = FormattableKernTextView()
		tv.formats = ["w*45d-_*asdf"]
		tv.text = "t(9"
		tv.maskAppearance = .whole(placeholders: [:])
		
		let result = tv.formattedText
		XCTAssertEqual(result, "t(459-_*asdf")
	}

	func testNonFormattedTextInTextView() throws {
		let tv = FormattableKernTextView()
		tv.text = "non-formatted text"

		let result = tv.formattedText
		XCTAssertEqual(result, "non-formatted text")
	}
}
