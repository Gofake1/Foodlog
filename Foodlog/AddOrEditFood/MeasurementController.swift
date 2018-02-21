//
//  MeasurementController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

infix operator ====: AssignmentPrecedence
func ====<A: Equatable>(lhs: inout A, rhs: A) -> Bool {
    defer { lhs = rhs }
    return lhs == rhs
}

class MeasurementController: NSObject {
    @IBOutlet weak var addOrEditVC: AddOrEditFoodViewController!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var valueRepresentationControl: UISegmentedControl!
    @IBOutlet weak var representationButton: UIButton!
    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var perRepresentationLabel: UILabel!
    
    private var measurementRepresentation: Food.MeasurementRepresentation {
        get { return addOrEditVC.foodEntry.food!.measurementRepresentation }
        set { addOrEditVC.foodEntry.food?.measurementRepresentationRaw = newValue.rawValue }
    }
    private var measurementValue: Data {
        get { return addOrEditVC.foodEntry.measurementValue }
        set { addOrEditVC.foodEntry.measurementValue = newValue }
    }
    private var measurementValueRepresentation: FoodEntry.MeasurementValueRepresentation {
        get { return addOrEditVC.foodEntry.measurementValueRepresentation }
        set { addOrEditVC.foodEntry.measurementValueRepresentationRaw = newValue.rawValue }
    }
    private lazy var representationPicker: UIAlertController = {
        func action(_ representation: Food.MeasurementRepresentation) -> UIAlertAction {
            return UIAlertAction(title: representation.plural, style: .default, handler: { [weak self] (_) in
                guard let _self = self else { return }
                if _self.mode == .editEntry {
                    _self.addOrEditVC.userChangedFoodInfo ||= !(_self.measurementRepresentation ==== representation)
                } else {
                    _self.measurementRepresentation = representation
                }
                _self.representationButton.setTitle(representation.plural, for: .normal)
                _self.perRepresentationLabel.text = "Information Per \(representation.singular)"
            })
        }
        
        let alert = UIAlertController(title: "Choose unit of measurement", message: nil, preferredStyle: .actionSheet)
        alert.addAction(action(.serving))
        alert.addAction(action(.milligram))
        alert.addAction(action(.gram))
        alert.addAction(action(.ounce))
        alert.addAction(action(.pound))
        alert.addAction(action(.fluidOunce))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        return alert
    }()
    private var mode: AddOrEditFoodViewController.Mode!
    
    func setup(_ mode: AddOrEditFoodViewController.Mode) {
        self.mode = mode
        valueRepresentationControl.selectedSegmentIndex = measurementValueRepresentation.rawValue
        representationButton.setTitle(measurementRepresentation.plural, for: .normal)
        representationButton.isEnabled = mode != .addEntryForExistingFood
        field.inputAccessoryView = toolbar
        switch measurementValueRepresentation {
        case .decimal:  field.text = measurementValue.to(Float.self).pretty
        case .fraction: field.text = (Fraction.decode(from: measurementValue) ?? Fraction()).description
        }
        perRepresentationLabel.text = "Information Per \(measurementRepresentation.singular)"
    }
    
    @IBAction func chooseValueRepresentation(_ sender: UISegmentedControl) {
        measurementValueRepresentation = FoodEntry.MeasurementValueRepresentation(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func showRepresentationsMenu() {
        addOrEditVC.present(representationPicker, animated: true, completion: nil)
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
}

extension MeasurementController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "0" {
            textField.text = ""
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        for character in string {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "/":
                continue
            default:
                return false
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch measurementValueRepresentation {
        case .decimal:
            if let decimal = Float(textField.text!) {
                measurementValue = Data(decimal)
                textField.text = decimal.pretty
            } else {
                measurementValue = Data(Float(0.0))
                textField.text = "0"
            }
        case .fraction:
            if let fraction = Fraction(textField.text!) {
                measurementValue = fraction.encode()!
                textField.text = fraction.description
            } else {
                measurementValue = Fraction().encode()!
                textField.text = "0"
            }
        }
    }
}

extension Food.MeasurementRepresentation {
    var plural: String {
        switch self {
        case .serving:      return "Servings"
        case .milligram:    return "Milligrams"
        case .gram:         return "Grams"
        case .ounce:        return "Ounces"
        case .pound:        return "Pounds"
        case .fluidOunce:   return "Fluid Ounces"
        }
    }
    
    var singular: String {
        switch self {
        case .serving:      return "Serving"
        case .milligram:    return "Milligram"
        case .gram:         return "Gram"
        case .ounce:        return "Ounce"
        case .pound:        return "Pound"
        case .fluidOunce:   return "Fluid Oz."
        }
    }
}

extension Fraction {
    init?(_ string: String) {
        enum ParseState {
            case expectNumeratorDigit
            case expectNumeratorDigitOrDivider
            case expectDenominatorDigit
        }
        
        var state = ParseState.expectNumeratorDigit
        var numeratorString = ""
        var denominatorString = ""
        for character in string {
            switch character {
            case ".", ",", "/":
                guard state == .expectNumeratorDigitOrDivider else { return nil }
                state = .expectDenominatorDigit
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                switch state {
                case .expectNumeratorDigit:
                    numeratorString += String(character)
                    state = .expectNumeratorDigitOrDivider
                case .expectNumeratorDigitOrDivider:
                    numeratorString += String(character)
                case .expectDenominatorDigit:
                    denominatorString += String(character)
                }
            default:
                return nil
            }
        }
        self.init(numerator: Int(numeratorString) ?? 0, denominator: Int(denominatorString) ?? 1)
    }
}
