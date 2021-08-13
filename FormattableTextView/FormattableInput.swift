//
//  FormattableInput.swift
//  FormattableTextView
//
//  Created by Михаил Мотыженков on 21.07.2018.
//  Copyright © 2018 Михаил Мотыженков. All rights reserved.
//

import Foundation
import UIKit

/// A way to draw the mask
///
/// - leftOnly: draw mask elements from the left side of inputed symbols
/// - leftAndRight: draw mask elements from the left side of inputed symbols and draw next mask element from the right side if current input area is finished
/// - whole: draw all mask elements; in this case it is your responsibility to set the same *monospaced* font in maskAttributes and inputAttributes
@frozen
public enum MaskAppearance {
	case leftOnly
	case leftAndRight
	case whole(placeholders: [Character: Character])
	
	fileprivate var isWhole: Bool {
		switch self {
		case .whole(_):
			return true
		default:
			return false
		}
	}
}

internal enum MaskState {
	case mask
	case input
}

internal struct MaskLayersDiff {
	var layersToAdd: [Int: CALayer]
	var layersToDelete: [Int]
	var layersToChangeFrames: [Int: CGPoint]
}

internal enum ActionForLayer {
	case change
	case add
}

internal enum ProcessAttributesResult {
	case withoutFormat
	case notAllowed
	case allowed(attributedString: NSAttributedString, numberOfDeletedSymbols: Int, maskLayersDiff: MaskLayersDiff)
}

public protocol FormattableInput: UITextInput {
	var currentFormat: String? { get }
	
	var formats: [String] { get set }
	
	var maskAppearance: FormattableTextView.MaskAppearance { get set }
	
	/// Allow inserting space character at the beginning of the text. It is required behavior in order to use iOS smart suggestions, e.g. telephone number.
	var allowSmartSuggestions: Bool { get set }
	
	/// Input symbols will be drawn with these attributes
	var inputAttributes: [NSAttributedString.Key : Any] { get set }
	
	/// Non-input symbols will be drawn with these attributes
	var maskAttributes: [NSAttributedString.Key : Any]! { get set }
	
	var formatSymbols: [Character : CharacterSet] { get set }
	
	
	/// x inset for input text and placeholders, may be set by user
	var insetX: CGFloat { get set }
	
	var keyboardType: UIKeyboardType { get set }
	
	var formattedText: String? { get }
}

internal protocol FormattableInputInternal: FormattableInput where Self: UIView {
	var internalAttributedText: NSAttributedString { get set }
	var currentFormat: String? { get set }
	
	var formatInputChars: Set<Character>! { get set }
	
	/// Non-input elements of format which will be drawn in separate layers
	var maskLayers: [Int: CALayer] { get set }
	var maskPlaceholders: [CALayer] { get set }

	var backgroundColor: UIColor? { get }
	
	/// real x inset for input text
	var internalInsetX: CGFloat { get set }
	
	/// real y inset for input text
	var internalInsetY: CGFloat { get set }
	
	var nonInputSymbolsAtTheEnd: String? { get set }
	
	func shouldAllowSmartSuggestion(_ range: NSRange, _ text: String) -> Bool
	func updateInsetY()
	func setLeftInset()
	func setupMask()
	func replaceText(inRange range: NSRange, withText text: String)
	func setupFormatChars()
	func processAttributesForTextAndMask(range: NSRange, replacementText: String) -> ProcessAttributesResult
	func setAttributedTextAndTextPosition(attributedString: NSAttributedString, location: Int, offset: Int, maskLayersDiff: MaskLayersDiff)
}

extension FormattableInputInternal {
	
	func shouldAllowSmartSuggestion(_ range: NSRange, _ text: String) -> Bool {
		return self.allowSmartSuggestions && range.location == 0 && range.length == 0 && text.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
	}
	
	private func getOrCreateCurrentLayer(maskLayers: [Int: CALayer], maskAttributes: [NSAttributedString.Key: Any], key: Int, prevFormat: String) -> (action: ActionForLayer, layer: CALayer) {
		if let layer = maskLayers[key] {
			return (action: .change, layer: layer)
		} else {
			let layer = CALayer(text: prevFormat, attributes: maskAttributes)
			return (action: .add, layer: layer)
		}
	}
	
	@discardableResult
	private func fillMaskLayersDiffAndIncrementDx(maskLayersDiff: inout MaskLayersDiff, maskLayers: [Int: CALayer], key: Int, prevFormat: String, dx: inout CGFloat) -> CGFloat {
		let currentLayerResult = getOrCreateCurrentLayer(maskLayers: maskLayers, maskAttributes: maskAttributes, key: key, prevFormat: prevFormat)
		let layer = currentLayerResult.layer
		guard let inputFont = inputAttributes[NSAttributedString.Key.font] as? UIFont, let maskFont = maskAttributes[NSAttributedString.Key.font] as? UIFont else { return 0 }
		let dy = internalInsetY.rounded() - (maskFont.lineHeight-inputFont.lineHeight)/2
		switch currentLayerResult.action {
		case .add:
			layer.frame.origin.x = dx
			layer.frame.origin.y = dy
			maskLayersDiff.layersToAdd[key] = layer
		case .change:
			var position = layer.frame.origin
			position.x = dx
			position.y = dy
			maskLayersDiff.layersToChangeFrames[key] = position
		}
		let offset = layer.bounds.width
		dx += offset
		return offset
	}
	
	private func calculateDx(dx: inout CGFloat, format: String, formatCurrentIndex: String.Index, inputString: String, lastInputStartIndex: String.Index, inputIndex: String.Index) {
		if maskAppearance.isWhole {
			let prevInput = String(format[format.startIndex..<formatCurrentIndex])
			let size = (prevInput as NSString).size(withAttributes: self.inputAttributes)
			dx = self.insetX + size.width
		} else {
			let prevInput = String(inputString[lastInputStartIndex..<inputIndex])
			let size = (prevInput as NSString).size(withAttributes: self.inputAttributes)
			dx += size.width
		}
	}
	
	private func addMaskPlaceholder(_ newMaskPlaceholders: inout [CALayer], _ char: Character, _ maskSymbolNumber: Int, _ symbolWidth: CGFloat) {
		switch maskAppearance {
		case .whole(let placeholders):
			guard let inputFont = inputAttributes[NSAttributedString.Key.font] as? UIFont, let maskFont = maskAttributes[NSAttributedString.Key.font] as? UIFont else { return }
			if let placeholderChar = placeholders[char] {
				let layer = CALayer(text: String(placeholderChar), attributes: maskAttributes)
				layer.frame.origin.y = internalInsetY.rounded() - (maskFont.lineHeight-inputFont.lineHeight)/2
				layer.frame.origin.x = insetX + CGFloat(maskSymbolNumber) * symbolWidth
				newMaskPlaceholders.append(layer)
			}
		default:
			break
		}
	}
	
	func setupMask() {
		setupFormatChars()
		replaceText(inRange: NSMakeRange(0, 0), withText: "")
	}
	
	func setupFormatChars() {
		formatInputChars = Set(formatSymbols.keys)
		processNonInputSymbolsAtTheEnd()
	}
	
	func setLeftInset() {
		guard let format = currentFormat else { return }
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
	
	func processAttributesForTextAndMask(range: NSRange, replacementText: String) -> ProcessAttributesResult {
		var result = processAttributesForTextAndMaskInternal(range: range, replacementText: replacementText, format: currentFormat)
		if case .allowed = result {
			return result
		}
		for format in formats {
			if format == currentFormat { continue }
			result = processAttributesForTextAndMaskInternal(range: range, replacementText: replacementText, format: format)
			switch result {
			case .notAllowed:
				continue
			default:
				currentFormat = format
				return result
			}
		}
		return result
	}
	
	private func processAttributesForTextAndMaskInternal(range: NSRange, replacementText: String, format: String?) -> ProcessAttributesResult {
		guard let format = format else {
			return .withoutFormat
		}
		var numberOfDeletedSymbols = 0
		var state = MaskState.mask
		var formatCurrentStartIndex = format.startIndex
		
		let mutableAttributedString = NSMutableAttributedString(string: (self.internalAttributedText.string as NSString).replacingCharacters(in: range, with: replacementText), attributes: self.inputAttributes)
		var inputSymbolNumber = 0
		var maskSymbolNumber = 0
		var inputIndex = mutableAttributedString.string.startIndex
		var formatCurrentIndex = format.startIndex
		var lastInputStartIndex = format.startIndex
		let maskLayers = self.maskLayers
		var dx: CGFloat = self.insetX
		var isFirstInputSymbol = true
		var shouldEnd = false
		var maskLayersDiff = MaskLayersDiff(layersToAdd: [Int: CALayer](), layersToDelete: [Int](), layersToChangeFrames: [Int: CGPoint]())
		let symbolWidth = format.isEmpty ? 0 : (String(format.first!) as NSString).size(withAttributes: inputAttributes).width
		var newMaskPlaceholders = [CALayer]()
		updateInsetY()
		
		for char in format {
			var allowIncrementingInputSymbolIndex = (inputIndex != mutableAttributedString.string.endIndex)
			let prevFormat = String(format[formatCurrentStartIndex..<formatCurrentIndex])
			let isUserSymbol = self.formatInputChars.contains(char)
			
			if state == .mask && isUserSymbol {
				state = .input
				lastInputStartIndex = inputIndex
				
				if isFirstInputSymbol {
					isFirstInputSymbol = false
					if !prevFormat.isEmpty {
						fillMaskLayersDiffAndIncrementDx(maskLayersDiff: &maskLayersDiff, maskLayers: maskLayers, key: formatCurrentStartIndex.utf16Offset(in: format), prevFormat: prevFormat, dx: &dx)
					}
				} else {
					let width = fillMaskLayersDiffAndIncrementDx(maskLayersDiff: &maskLayersDiff, maskLayers: maskLayers, key: formatCurrentStartIndex.utf16Offset(in: format), prevFormat: prevFormat, dx: &dx)
					if (maskAppearance.isWhole && allowIncrementingInputSymbolIndex || !maskAppearance.isWhole) && !mutableAttributedString.string.isEmpty {
						mutableAttributedString.addAttribute(NSAttributedString.Key.kern, value: width, range: NSMakeRange(inputSymbolNumber-1, 1))
					}
				}
				if shouldEnd {
					break
				}
			} else if state == .input && !isUserSymbol {
				state = .mask
				calculateDx(dx: &dx, format: format, formatCurrentIndex: formatCurrentIndex, inputString: mutableAttributedString.string, lastInputStartIndex: lastInputStartIndex, inputIndex: inputIndex)
				formatCurrentStartIndex = formatCurrentIndex
			}
			
			if state == .input {
				if shouldEnd || (mutableAttributedString.string.isEmpty && !maskAppearance.isWhole) {
					break
				}
				// Check if current area of input string starts with a tail of previous mask area. If it is true then delete those characters.
				// It is needed when user pastes text with mask symbols.
				if allowIncrementingInputSymbolIndex {
					if !self.formatSymbols[char]!.contains(mutableAttributedString.string[inputIndex].unicodeScalars.first!) {
						let prevFormat = String(format[formatCurrentStartIndex..<formatCurrentIndex])
						if prevFormat.isEmpty {
							return .notAllowed
						}
						// Delete mask characters from input string.
						// TODO: better implementation
						for formatChar in prevFormat {
							if mutableAttributedString.string[inputIndex] == formatChar {
								mutableAttributedString.deleteCharacters(in: NSMakeRange(inputSymbolNumber, 1))
								numberOfDeletedSymbols += 1
								allowIncrementingInputSymbolIndex = false
								if inputIndex == mutableAttributedString.string.endIndex {
									break
								}
							} else {
								return .notAllowed
							}
						}
					}
					inputSymbolNumber += 1
					if inputIndex != mutableAttributedString.string.endIndex {
						inputIndex = mutableAttributedString.string.index(after: inputIndex)
					}
				}
				if maskAppearance.isWhole && !allowIncrementingInputSymbolIndex {
					addMaskPlaceholder(&newMaskPlaceholders, char, maskSymbolNumber, symbolWidth)
				}
			}
			if inputIndex == mutableAttributedString.string.endIndex && !mutableAttributedString.string.isEmpty && !shouldEnd {
				var shouldBreak = false
				switch maskAppearance {
				case .leftOnly:
					shouldBreak = true
				case .leftAndRight:
					shouldEnd = true
				case .whole:
					break // exit from switch statement
				}
				if shouldBreak {
					break // exit from loop
				}
			}
			formatCurrentIndex = format.index(after: formatCurrentIndex)
			maskSymbolNumber += 1
		}
		// A condition which prevents user from inserting too many symbols
		if inputIndex < mutableAttributedString.string.endIndex {
			return .notAllowed
		}
		
		maskPlaceholders.forEach { $0.removeFromSuperlayer() }
		newMaskPlaceholders.forEach {
			self.layer.addSublayer($0)
		}
		maskPlaceholders = newMaskPlaceholders
		
		if let nonInputSymbolsAtTheEnd = self.nonInputSymbolsAtTheEnd {
			var shouldCalculateDx = false
			switch maskAppearance {
			case .leftOnly:
				shouldCalculateDx = true
			case .leftAndRight:
				shouldCalculateDx = state == .input
			case .whole(_):
				shouldCalculateDx = false
			}
			if shouldCalculateDx {
				calculateDx(dx: &dx, format: format, formatCurrentIndex: formatCurrentIndex, inputString: mutableAttributedString.string, lastInputStartIndex: lastInputStartIndex, inputIndex: inputIndex)
			}
			fillMaskLayersDiffAndIncrementDx(maskLayersDiff: &maskLayersDiff, maskLayers: maskLayers, key: formatCurrentIndex.utf16Offset(in: format), prevFormat: nonInputSymbolsAtTheEnd, dx: &dx)
		}
		
		let indicesToAdd = Set(maskLayersDiff.layersToAdd.map { $0.key })
		let indicesToChange = Set(maskLayersDiff.layersToChangeFrames.map { $0.key })
		maskLayersDiff.layersToDelete = self.maskLayers.map { $0.key }.filter { !indicesToAdd.contains($0) && !indicesToChange.contains($0) }
		
		return .allowed(attributedString: mutableAttributedString, numberOfDeletedSymbols: numberOfDeletedSymbols, maskLayersDiff: maskLayersDiff)
	}
	
	func setAttributedTextAndTextPosition(attributedString: NSAttributedString, location: Int, offset: Int, maskLayersDiff: MaskLayersDiff) {
		self.internalAttributedText = attributedString
		for key in maskLayersDiff.layersToDelete {
			let layer = self.maskLayers.removeValue(forKey: key)
			layer?.removeFromSuperlayer()
		}
		for (key, value) in maskLayersDiff.layersToAdd {
			self.maskLayers[key] = value
			self.layer.addSublayer(value)
		}
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		for (key, value) in maskLayersDiff.layersToChangeFrames {
			let layer = self.maskLayers[key]
			layer?.frame.origin = value
		}
		CATransaction.commit()
		
		DispatchQueue.main.async { // this async call fixes the cursor position when you try to insert large text
			if let pos = self.position(from: self.beginningOfDocument, offset: location+offset) {
				self.selectedTextRange = self.textRange(from: pos, to: pos)
			}
		}
	}
	
	func updateInsetY() {
		if let inputFont = self.inputAttributes[NSAttributedString.Key.font] as? UIFont {
			internalInsetY = (self.bounds.height - inputFont.lineHeight)/2
		}
	}
	
	func processNonInputSymbolsAtTheEnd() {
		guard let format = self.currentFormat else { return }
		var nonInputSymbolsAtTheEnd: String = ""
		for char in format {
			let isUserSymbol = self.formatInputChars.contains(char)
			if isUserSymbol {
				nonInputSymbolsAtTheEnd = ""
			} else {
				nonInputSymbolsAtTheEnd.append(char)
			}
		}
		self.nonInputSymbolsAtTheEnd = nonInputSymbolsAtTheEnd
	}
}

public extension FormattableInput {
	var formattedText: String? {
		get {
			var text = text(in: textRange(from: self.beginningOfDocument, to: self.endOfDocument) ?? UITextRange()) ?? ""
			guard let currentFormat = currentFormat else {
				return text
			}

			var result = ""
			
			var shouldBreakLoopForLeftAndRight = false
			var isWholeEnding = false
			for (index, char) in currentFormat.enumerated() {
				if formatSymbols.keys.contains(char) && !isWholeEnding {
					if shouldBreakLoopForLeftAndRight || text.isEmpty {
						break
					}
					result.append(text[text.startIndex])
					text.remove(at: text.startIndex)
					if text.isEmpty {
						var shouldBreakLoop = false
						switch self.maskAppearance {
						case .leftOnly:
							shouldBreakLoop = true
						case .leftAndRight:
							shouldBreakLoopForLeftAndRight = true
						case .whole:
							isWholeEnding = true
						}
						if shouldBreakLoop {
							break
						}
					}
				} else {
					let currentIndex = currentFormat.index(result.startIndex, offsetBy: index)
					result.append(currentFormat[currentIndex])
				}
			}
			return result
		}
	}
}
