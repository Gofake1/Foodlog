//
//  AmountController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class AmountController: NSObject {
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var unitBarButton: UIBarButtonItem!
    @IBOutlet weak var valueRepresentationControl: UISegmentedControl!
    
    var field: UITextField!
    private var context: AmountControllerContext!
    
    func setup(_ context: AmountControllerContext) {
        self.context = context
        field.delegate = self
        field.inputAccessoryView = toolbar
        if let text = context.amount.string(from: context.representation) {
            field.text = text + context.unit.suffix
        }
        unitBarButton.title = context.unit.buttonTitle
        valueRepresentationControl.selectedSegmentIndex = context.representation.segmentIndex
    }
    
    @IBAction func chooseRepresentation(_ sender: UISegmentedControl) {
        guard let representation = FoodEntry.MeasurementRepresentation(segmentIndex: sender.selectedSegmentIndex)
            else { return }
        context.representation = representation
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
    
    @IBAction func showUnitMenu() {
        let unitPicker: UIAlertController = {
            let alert = UIAlertController(title: "Choose unit of measurment", message: nil, preferredStyle: .actionSheet)
            for unit in context.defaultUnit.compatibleUnits {
                alert.addAction(UIAlertAction(title: unit.buttonTitle, style: .default, handler: { [weak self] _ in
                    self!.context.unit = unit
                    self!.unitBarButton.title = unit.buttonTitle
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            return alert
        }()
        UIApplication.shared.keyWindow!.rootViewController!.present(unitPicker, animated: true)
    }
}

extension AmountController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "0" {
            textField.text = ""
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        return string.isValidForDecimalOrFractionalInput
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch context.representation {
        case .decimal:
            if let decimal = Float(textField.text!), let text = decimal.pretty {
                context.amount = Data(decimal)
                textField.text = text + context.unit.suffix
            } else {
                context.amount = Data(Float(0.0))
                textField.text = "0"
            }
        case .fraction:
            if let fraction = Fraction(textField.text!) {
                context.amount = fraction.encode()!
                textField.text = fraction.description + context.unit.suffix
            } else {
                context.amount = Fraction().encode()!
                textField.text = "0"
            }
        }
    }
}

extension AmountController {
    final class ExistingFoodEntry {
        private let changes: Changes<FoodEntry>
        private let foodEntry: FoodEntry
        
        init(_ foodEntry: FoodEntry, _ changes: Changes<FoodEntry>) {
            self.foodEntry = foodEntry
            self.changes = changes
        }
    }
    
    final class NewFoodEntry {
        private let foodEntry: FoodEntry
        
        init(_ foodEntry: FoodEntry) {
            self.foodEntry = foodEntry
        }
    }
}

protocol AmountControllerContext {
    var amount: Data { get set }
    var defaultUnit: Food.Unit { get }
    var representation: FoodEntry.MeasurementRepresentation { get set }
    var unit: Food.Unit { get set }
}

extension AmountController.ExistingFoodEntry: AmountControllerContext {
    var amount: Data {
        get { return foodEntry.measurement }
        set {
            changes.insert(change: \FoodEntry.measurement)
            foodEntry.measurement = newValue
        }
    }
    var defaultUnit: Food.Unit {
        return foodEntry.food!.servingSizeUnit
    }
    var representation: FoodEntry.MeasurementRepresentation {
        get { return foodEntry.measurementRepresentation }
        set {
            changes.insert(change: \FoodEntry.measurementRepresentationRaw)
            foodEntry.measurementRepresentation = newValue
        }
    }
    var unit: Food.Unit {
        get { return foodEntry.measurementUnit }
        set {
            changes.insert(change: \FoodEntry.measurementUnitRaw)
            foodEntry.measurementUnit = newValue
        }
    }
}

extension AmountController.NewFoodEntry: AmountControllerContext {
    var amount: Data {
        get { return foodEntry.measurement }
        set { foodEntry.measurement = newValue }
    }
    var defaultUnit: Food.Unit {
        return foodEntry.food!.servingSizeUnit
    }
    var representation: FoodEntry.MeasurementRepresentation {
        get { return foodEntry.measurementRepresentation }
        set { foodEntry.measurementRepresentation = newValue }
    }
    var unit: Food.Unit {
        get { return foodEntry.measurementUnit }
        set { foodEntry.measurementUnit = newValue }
    }
}

extension Food.Unit {
    fileprivate var buttonTitle: String {
        switch self {
        case .none:         return "Servings"
        case .gram:         return "Grans"
        case .milligram:    return "Milligrams"
        case .ounce:        return "Ounces"
        case .milliliter:   return "Milliliters"
        case .fluidOunce:   return "Fluid Ounces"
        }
    }
    fileprivate var compatibleUnits: [Food.Unit] {
        switch self {
        case .none:
            return [.none]
        case .gram:         fallthrough
        case .milligram:    fallthrough
        case .ounce:
            return [.none, .gram, .milligram, .ounce]
        case .milliliter: fallthrough
        case .fluidOunce:
            return [.none, .milliliter, .fluidOunce]
        }
    }
}

extension FoodEntry.MeasurementRepresentation {
    fileprivate var segmentIndex: Int {
        switch self {
        case .decimal:  return 0
        case .fraction: return 1
        }
    }
    
    fileprivate init?(segmentIndex: Int) {
        switch segmentIndex {
        case 0:     self = .decimal
        case 1:     self = .fraction
        default:    return nil
        }
    }
}

extension Fraction {
    fileprivate init?(_ string: String) {
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
