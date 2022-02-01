//
//  SnapshotTestHelper.swift
//  FormattableTextViewSnapshotTests
//
//  Created by Mikhail Motyzhenkov on 28.01.2022.
//  Copyright © 2022 Михаил Мотыженков. All rights reserved.
//

import Foundation
import SnapshotTesting
import UIKit
import XCTest
@testable import FormattableTextView

enum FormattableInputType {
	case field
	case view
}

func field(type: FormattableInputType) -> UIView & FormattableInput {
	var field: UIView & FormattableInput
	let frame = CGRect(x: 0, y: 0, width: 240, height: 48)
	switch type {
	case .field:
		field = FormattableTextField(frame: frame)
	case .view:
		field = FormattableKernTextView(frame: frame)
		(field as? FormattableKernTextView)?.shouldUpdateOnFirstLayout = false
	}
	field.backgroundColor = UIColor.white
	return field
}

func assert(_ view: UIView,
			file: StaticString = #file,
			testName: String = #function,
			line: UInt = #line) {
	guard UIScreen.main.nativeScale == 3 else {
		fatalError("Use 3x device")
	}
	let named = "iOS\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)"
	if let result = verifySnapshot(matching: view, as: .image, named: named, file: file, testName: testName, line: line) {
		XCTFail(result)
	}
}
