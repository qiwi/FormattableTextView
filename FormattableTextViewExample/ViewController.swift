//
//  ViewController.swift
//  FormattedTextView
//
//  Created by Михаил Мотыженков on 10.07.2018.
//  Copyright © 2018 Михаил Мотыженков. All rights reserved.
//

import UIKit
import FormattableTextView

final class ViewController: UIViewController {
	
	let wholeMaskAttributes = [NSAttributedString.Key.font: UIFont(name: "Menlo", size: 16)!,
						  NSAttributedString.Key.foregroundColor: UIColor.lightGray]
	let wholeInputAttributes = [NSAttributedString.Key.font: UIFont(name: "Menlo", size: 16)!]
	let normalMaskAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
							   NSAttributedString.Key.foregroundColor: UIColor.lightGray]
	let normalInputAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    
    @IBOutlet weak var labelFontSize: UILabel!
    @IBOutlet weak var labelAlpha: UILabel!
	@IBOutlet weak var stackFontSize: UIStackView!
	@IBOutlet weak var stackBold: UIStackView!
	@IBOutlet weak var stepper: UIStepper!
	
    let colors = [UIColor.black, UIColor.lightGray, UIColor.blue, UIColor.green, UIColor.red, UIColor.yellow]
    var textFields: [FormattableInput & UIView]!
    var alpha = 1.0
	let formats = [
		["dddd dddd dddd dddd"],
		["wdddww dd"],
		["+7(ddd)ddd-dd-dd",
		"+44 07ddd dddddd"],
		["dddddd ₽"]
	]
	
	override func viewDidLoad() {
        super.viewDidLoad()
		initTextField()
    }
	
	private func initTextView() {
		initFormattable(type: FormattableKernTextView.self)
	}
	
	private func initTextField() {
		initFormattable(type: FormattableTextField.self)
	}
	
	private func initFormattable<T>(type: T.Type) where T: FormattableInput & UIView {
		
		let elements = view.getFormattableElements()
		textFields = []
		for i in 0..<elements.count {
			let oldView = elements[i]
			let tv = T.init()
			tv.keyboardType = oldView.keyboardType
			tv.backgroundColor = UIColor.white
			tv.formats = formats[i]
			tv.formatSymbols = ["d": CharacterSet.decimalDigits,
								"0": CharacterSet(charactersIn: "0"),
								"4": CharacterSet(charactersIn: "4"),
								"7": CharacterSet(charactersIn: "7"),
								"w": CharacterSet.letters,
								"*": CharacterSet(charactersIn: "").inverted]
			tv.layer.cornerRadius = 5
			if let superview = oldView.superview {
				oldView.removeFromSuperview()
				superview.addSubview(tv)
				tv.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([tv.leftAnchor.constraint(equalTo: superview.leftAnchor),
											 tv.topAnchor.constraint(equalTo: superview.topAnchor),
											 tv.rightAnchor.constraint(equalTo: superview.rightAnchor),
											 tv.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
											 tv.heightAnchor.constraint(equalToConstant: oldView.bounds.height)])
			}
			textFields.append(tv)
		}
		buttonMaskWholeTouched(nil)
	}
	
	@IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			initTextField()
		case 1:
			initTextView()
		default:
			fatalError()
		}
	}
	
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        labelFontSize.text = "\(Int(sender.value))"
        for tv in textFields {
            let font = tv.maskAttributes[NSAttributedString.Key.font] as! UIFont
            tv.maskAttributes[NSAttributedString.Key.font] = UIFont(descriptor: font.fontDescriptor, size: CGFloat(sender.value))
        }
    }
    
    @IBAction func stepperAlphaChanged(_ sender: UIStepper) {
        labelAlpha.text = "\(String(format: "%.1f", sender.value))"
        alpha = sender.value
        for tv in textFields {
            let color = tv.maskAttributes[NSAttributedString.Key.foregroundColor] as! UIColor
            tv.maskAttributes[NSAttributedString.Key.foregroundColor] = color.withAlphaComponent(CGFloat(alpha))
        }
    }
    
    @IBAction func buttonColorTouched(_ sender: UIButton) {
        guard let color = sender.backgroundColor else { return }
        for tv in textFields {
            tv.maskAttributes[NSAttributedString.Key.foregroundColor] = color.withAlphaComponent(CGFloat(alpha))
        }
    }
    
    @IBAction func buttonBoldTouched(_ sender: UIButton) {
        for tv in textFields {
            let font = tv.maskAttributes[NSAttributedString.Key.font] as! UIFont
            tv.maskAttributes[NSAttributedString.Key.font] = font.bold()
        }
    }
    
    @IBAction func buttonItalicTouched(_ sender: UIButton) {
        for tv in textFields {
            let font = tv.maskAttributes[NSAttributedString.Key.font] as! UIFont
            tv.maskAttributes[NSAttributedString.Key.font] = font.italic()
        }
    }
    
    @IBAction func buttonNormalTouched(_ sender: UIButton) {
        for tv in textFields {
            let font = tv.maskAttributes[NSAttributedString.Key.font] as! UIFont
            tv.maskAttributes[NSAttributedString.Key.font] = font.regular()
        }
    }
	
	@IBAction func buttonMaskLeftOnlyTouched(_ sender: UIButton) {
		for tv in textFields {
			tv.maskAttributes = normalMaskAttributes
			tv.inputAttributes = normalInputAttributes
			tv.maskAppearance = .leftOnly
		}
		stackFontSize.toggle(enable: true)
		stackBold.toggle(enable: true)
		stepper.value = Double((normalMaskAttributes[NSAttributedString.Key.font] as? UIFont)?.pointSize ?? 16)
		labelFontSize.text = "\(Int(stepper.value))"
	}
	
	@IBAction func buttonMaskLeftAndRightTouched(_ sender: UIButton) {
		for tv in textFields {
			tv.maskAttributes = normalMaskAttributes
			tv.inputAttributes = normalInputAttributes
			tv.maskAppearance = .leftAndRight
		}
		stackFontSize.toggle(enable: true)
		stackBold.toggle(enable: true)
		stepper.value = Double((normalMaskAttributes[NSAttributedString.Key.font] as? UIFont)?.pointSize ?? 16)
		labelFontSize.text = "\(Int(stepper.value))"
	}
	
	@IBAction func buttonMaskWholeTouched(_ sender: UIButton?) {
		for tv in textFields {
			tv.maskAttributes = wholeMaskAttributes
			tv.inputAttributes = wholeInputAttributes
			tv.maskAppearance = .whole(placeholders: ["d": "0",
													  "0": "0",
													  "4": "4",
													  "7": "7",
													  "w": "A",
													  "*": "*"])
		}
		stackFontSize.toggle(enable: false)
		stackBold.toggle(enable: false)
		stepper.value = Double((wholeMaskAttributes[NSAttributedString.Key.font] as? UIFont)?.pointSize ?? 16)
		labelFontSize.text = "\(Int(stepper.value))"
	}
	
	@IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
		self.view.endEditing(true)
	}
}

extension UIView {
    func getFormattableElements() -> [FormattableInput & UIView] {
        var result = [FormattableInput & UIView]()
        for subview in self.subviews {
            if let element = subview as? FormattableInput & UIView {
                result.append(element)
            }
            let subResult = subview.getFormattableElements()
            result.append(contentsOf: subResult)
        }
        return result
    }
	
	func toggle(enable: Bool) {
		self.isUserInteractionEnabled = enable
		self.alpha = self.isUserInteractionEnabled ? 1.0 : 0.5
	}
}


extension UIFont {
	private func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
		let descriptor = fontDescriptor.withSymbolicTraits(traits)
		return UIFont(descriptor: descriptor!, size: 0)
	}
	
	func bold() -> UIFont {
		return withTraits(traits: .traitBold)
	}
	
	func italic() -> UIFont {
		return withTraits(traits: .traitItalic)
	}
	
	func regular() -> UIFont {
		var traits = fontDescriptor.symbolicTraits
		traits.remove([.traitBold, .traitItalic])
		let descriptor = fontDescriptor.withSymbolicTraits(traits)
		return UIFont(descriptor: descriptor!, size: 0)
	}
}
