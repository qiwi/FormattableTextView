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
	convenience init(text: String, attributes: [NSAttributedString.Key: Any], useIntegerCoordinates: Bool) {
		let size = (text as NSString).size(withAttributes: attributes)
		let realSize = useIntegerCoordinates ? CGSize(width: round(size.width), height: round(size.height)) : size
		self.init()
		self.frame = CGRect(origin: CGPoint.zero, size: realSize)
		
		UIGraphicsBeginImageContextWithOptions(realSize, false, UIScreen.main.scale)
		(text as NSString).draw(with: CGRect(origin: CGPoint.zero, size: realSize), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
		let img = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.contents = img?.cgImage
	}
}
