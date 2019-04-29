//
//  FormattableTextField.swift
//  FormattableTextView
//
//  Created by Mikhail Motyzhenkov on 22/01/2019.
//  Copyright © 2019 Михаил Мотыженков. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
open class FormattableTextField: UITextField, FormattableInput, FormattableInputInternal {
	
	internal var internalAttributedText: NSAttributedString {
		get {
			return self.attributedText ?? NSAttributedString(string: "")
		}
		set {
			self.attributedText = newValue
		}
	}
	
	@IBInspectable open var format: String? = nil  {
		didSet {
			if oldValue != nil {
				clearText()
			}
			setupMask()
			setLeftInset()
			maskPlaceholders.forEach { $0.removeFromSuperlayer() }
			updateMask()
		}
	}
	
	public var formatSymbols: [Character: CharacterSet] = ["d": CharacterSet.decimalDigits,
														   "w": CharacterSet.letters,
														   "*": CharacterSet(charactersIn: "").inverted] {
		didSet {
			setupFormatChars()
		}
	}
	
	/// Input symbols will be drawn with these attributes
	public var inputAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)] {
		didSet {
			for (key, value) in inputAttributes {
				maskAttributes[key] = value
			}
		}
	}
	
	/// Non-input symbols will be drawn with these attributes
	public var maskAttributes: [NSAttributedString.Key: Any]! {
		didSet {
			updateMask()
		}
	}
	
	public var maskAppearance = MaskAppearance.leftOnly {
		didSet {
			maskPlaceholders.forEach { $0.removeFromSuperlayer() }
			updateMask()
		}
	}
	private func updateMask() {
		setLeftInset()
		for layer in maskLayers {
			layer.value.removeFromSuperlayer()
		}
		maskLayers = [Int: CALayer]()
		_ = self.delegateProxy.textField(self, shouldChangeCharactersIn: NSMakeRange(0, self.text?.count ?? 0), replacementString: self.text ?? "")
	}
	
	internal var maskLayers = [Int: CALayer]()
	
	var maskPlaceholders = [CALayer]()
	
	internal var formatInputChars: Set<Character>!
	
	@IBInspectable public var insetX: CGFloat = 5 {
		didSet {
			layoutIfNeeded()
		}
	}
	
	internal var internalInsetX: CGFloat = 0
	
	internal var internalInsetY: CGFloat = 0
	
	override open func textRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.insetBy(dx: internalInsetX + insetX, dy: internalInsetY)
	}
	
	override open func editingRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.insetBy(dx: internalInsetX + insetX, dy: internalInsetY)
	}
	
	private var delegateProxy = DelegateProxy()
	
	override open var delegate: UITextFieldDelegate? {
		get {
			return delegateProxy
		}
		set {
			self.delegateProxy.userDelegate = newValue
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		super.delegate = delegateProxy
		self.customInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		super.delegate = delegateProxy
		self.customInit()
	}
	
	private func customInit() {
		setupMask()
		maskAttributes = inputAttributes
	}
	
	private func setupFormatChars() {
		formatInputChars = Set(formatSymbols.keys)
	}
	
	private func setupMask() {
		setupFormatChars()
		replaceText(inRange: NSMakeRange(0, 0), withText: "")
	}
	
	private func replaceText(inRange range: NSRange, withText text: String) {
		let result = self.processAttributesForTextAndMask(range: range, replacementText: text)
		switch result {
		case .allowed(let attributedString, _, _):
			self.attributedText = attributedString
		default:
			break
		}
	}
	
	private func clearText() {
		if !(text?.isEmpty ?? false) {
			text = ""
		}
	}
	
	private func setLeftInset() {
		guard let format = format else { return }
		var index = format.startIndex
		for char in format {
			if self.formatInputChars.contains(char) {
				if index != format.startIndex {
					let prevFormat = String(format[format.startIndex..<index])
					let width = (prevFormat as NSString).size(withAttributes: self.maskAttributes).width
					self.internalInsetX = width
				}
				break
			}
			index = format.index(after: index)
		}
	}
	
	var isFirstLayout = true
	open override func layoutSubviews() {
		super.layoutSubviews()
		if isFirstLayout && self.bounds != CGRect.zero {
			isFirstLayout = false
			_ = self.delegateProxy.textField(self, shouldChangeCharactersIn: NSMakeRange(0, self.text?.count ?? 0), replacementString: self.text ?? "")
		}
	}
}

extension FormattableTextField {
	private final class DelegateProxy: NSObject, UITextFieldDelegate {
		weak var userDelegate: UITextFieldDelegate?
		
		override func responds(to aSelector: Selector!) -> Bool {
			if let userDelegate = userDelegate, userDelegate.responds(to: aSelector) {
				return true
			} else {
				return super.responds(to: aSelector)
			}
		}
		
		override func forwardingTarget(for aSelector: Selector!) -> Any? {
			if let userDelegate = userDelegate, userDelegate.responds(to: aSelector) {
				return userDelegate
			} else {
				return super.forwardingTarget(for: aSelector)
			}
		}
		
		func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
			let text = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
			let userResult = userDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string)
			
			guard let formattableTextField = textField as? FormattableInputInternal else { fatalError() }
			let processResult = formattableTextField.processAttributesForTextAndMask(range: range, replacementText: text)
			switch processResult {
			case .allowed(let attributedString, let numberOfDeletedSymbols, let maskLayersDiff):
				if let userResult = userResult {
					if userResult {
						formattableTextField.setAttributedTextAndTextPosition(attributedString: attributedString, location: range.location, offset: text.count-numberOfDeletedSymbols, maskLayersDiff: maskLayersDiff)
					}
				} else {
					formattableTextField.setAttributedTextAndTextPosition(attributedString: attributedString, location: range.location, offset: text.count-numberOfDeletedSymbols, maskLayersDiff: maskLayersDiff)
				}
				return false
			case .notAllowed:
				return false
			case .withoutFormat:
				return userResult ?? true
			}
		}
	}
}
