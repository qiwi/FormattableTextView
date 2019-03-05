//
//  CALayer+AttributedText.swift
//  FormattableTextView
//
//  Created by Mikhail Motyzhenkov on 16/10/2018.
//  Copyright © 2018 Михаил Мотыженков. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
	convenience init(text: String, attributes: [NSAttributedString.Key: Any]) {
		let size = (text as NSString).size(withAttributes: attributes)
		self.init()
		self.frame = CGRect(origin: CGPoint.zero, size: size)
		
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		(text as NSString).draw(with: CGRect(origin: CGPoint.zero, size: size), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
		let img = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.contents = img?.cgImage
	}
}
