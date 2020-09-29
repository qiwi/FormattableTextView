//
//  FormattableTextView.swift
//  FormattableTextView
//
//  Created by Михаил Мотыженков on 10.07.2018.
//  Copyright © 2018 Михаил Мотыженков. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
open class FormattableKernTextView: UITextView, FormattableInput, FormattableInputInternal {
	
	internal var internalAttributedText: NSAttributedString {
		get {
			return self.attributedText
		}
		set {
			self.attributedText = newValue
		}
	}
	
	public convenience init() {
		self.init(frame: CGRect.zero, textContainer: nil)
	}
	
	public override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		super.delegate = delegateProxy
		self.customInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		super.delegate = delegateProxy
		self.customInit()
	}
	
	private func customInit() {
		textContainer.lineFragmentPadding = 0
		textContainerInset = UIEdgeInsets.zero
		setupMask()
		maskAttributes = inputAttributes
		typingAttributes = inputAttributes
		updateInsetX()
	}
    
    private var delegateProxy = DelegateProxy()
    
    override open var delegate: UITextViewDelegate? {
        get {
            return delegateProxy
        }
        set {
            self.delegateProxy.userDelegate = newValue
        }
    }
    
    override open var text: String! {
        get {
            return super.text
        }
        set {
            replaceText(inRange: NSMakeRange(0, super.text.count), withText: newValue)
        }
    }
	
	public var allowSmartSuggestions: Bool = false
    
	internal func replaceText(inRange range: NSRange, withText text: String) {
		let result = self.processAttributesForTextAndMask(range: range, replacementText: text)
		switch result {
		case .allowed(let attributedString, let numberOfDeletedSymbols, let maskLayersDiff):
			setAttributedTextAndTextPosition(attributedString: attributedString, location: range.location, offset: text.count-numberOfDeletedSymbols, maskLayersDiff: maskLayersDiff)
		default:
			break
		}
	}
    
    private func clearText() {
        if !text.isEmpty {
            text = ""
        }
    }
    
    public var formats: [String] = [] {
        didSet {
			if !oldValue.isEmpty {
                clearText()
            }
            setupMask()
			maskPlaceholders.forEach { $0.removeFromSuperlayer() }
			updateMask()
			processNonInputSymbolsAtTheEnd()
        }
    }
	
	public internal(set) var currentFormat: String?
	
	private func updateMask() {
		setLeftInset()
		for layer in maskLayers {
			layer.value.removeFromSuperlayer()
		}
		maskLayers = [Int: CALayer]()
		_ = self.delegateProxy.textView(self, shouldChangeTextIn: NSMakeRange(0, self.text.count), replacementText: self.text)
	}
	
	public var maskAppearance = MaskAppearance.leftOnly {
		didSet {
			maskPlaceholders.forEach { $0.removeFromSuperlayer() }
			updateMask()
		}
	}
	
	internal var maskPlaceholders = [CALayer]()
	internal var nonInputSymbolsAtTheEnd: String?
	
	public var insetX: CGFloat = 5 {
		didSet {
			updateInsetX()
		}
	}
	
	private var _internalInsetX: CGFloat = 0
	internal var internalInsetX: CGFloat {
		get {
			return self.textContainerInset.left
		}
		set {
			_internalInsetX = newValue
			updateInsetX()
		}
	}
	
	private func updateInsetX() {
		self.textContainerInset.left = _internalInsetX.rounded() + insetX
	}
	
	internal var internalInsetY: CGFloat {
		get {
			return self.textContainerInset.top
		}
		set {
			self.textContainerInset.top = newValue.rounded()
		}
	}
    
    private var coreIndicesInPureInputSymbols = [Int: CGFloat]()
    
    /// Input symbols will be drawn with these attributes
    public var inputAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)] {
        didSet {
            for (key, value) in inputAttributes {
                maskAttributes[key] = value
            }
			typingAttributes = inputAttributes
        }
    }
    
    /// Non-input symbols will be drawn with these attributes
    public var maskAttributes: [NSAttributedString.Key: Any]! {
        didSet {
            updateMask()
        }
    }
    
    internal var maskLayers = [Int: CALayer]()
    
    public var formatSymbols: [Character: CharacterSet] = ["d": CharacterSet.decimalDigits,
                                                         "w": CharacterSet.letters,
                                                         "*": CharacterSet(charactersIn: "").inverted] {
        didSet {
            setupFormatChars()
        }
    }
    internal var formatInputChars: Set<Character>!
	
	private var isFirstLayout = true
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		if isFirstLayout && self.bounds != CGRect.zero {
			isFirstLayout = false
			_ = self.delegateProxy.textView(self, shouldChangeTextIn: NSMakeRange(0, self.text.count), replacementText: "")
		}
	}
}

extension FormattableKernTextView {
	private final class DelegateProxy: NSObject, UITextViewDelegate {
		weak var userDelegate: UITextViewDelegate?
		
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
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			guard let formattableTextView = textView as? FormattableInputInternal else { fatalError() }
            
			let text = text.count == 1 ? text : text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
			let userResult = userDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text)
			
			let processResult = formattableTextView.processAttributesForTextAndMask(range: range, replacementText: text)
			switch processResult {
			case .allowed(let attributedString, let numberOfDeletedSymbols, let maskLayersDiff):
				if let userResult = userResult {
					if userResult {
						formattableTextView.setAttributedTextAndTextPosition(attributedString: attributedString, location: range.location, offset: text.count-numberOfDeletedSymbols, maskLayersDiff: maskLayersDiff)
					}
				} else {
					formattableTextView.setAttributedTextAndTextPosition(attributedString: attributedString, location: range.location, offset: text.count-numberOfDeletedSymbols, maskLayersDiff: maskLayersDiff)
				}
				if let userDelegate = userDelegate, userDelegate.responds(to: #selector(UITextViewDelegate.textViewDidChange(_:))) {
					userDelegate.textViewDidChange?(textView)
				}
                if formattableTextView.shouldAllowSmartSuggestion(range, text) { return true }
				return false
			case .notAllowed:
                if formattableTextView.shouldAllowSmartSuggestion(range, text) { return true }
				return false
			case .withoutFormat:
				return userResult ?? true
			}
		}
	}
}
