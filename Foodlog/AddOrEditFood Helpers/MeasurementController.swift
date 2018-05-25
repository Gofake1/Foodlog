//
//  MeasurementController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class MeasurementUnitController: NSObject {
    // A: Adding/editing food entry
    @IBOutlet weak var unitBarButton: UIBarButtonItem!
    @IBOutlet weak var unitLabel: UILabel!
    // B: Editing food info
    @IBOutlet weak var unitButton: UIButton!
    // A & B
    @IBOutlet weak var perUnitLabel: UILabel!
    @IBOutlet weak var viewController: UIViewController!
    
    private var context: MeasurementUnitControllerContext!
    private lazy var unitPicker: UIAlertController = {
        func action(_ unit: Food.MeasurementUnit) -> UIAlertAction {
            return UIAlertAction(title: unit.plural, style: .default, handler: { [weak self] _ in
                self!.context.unit = unit
                self!.unitBarButton.title = unit.plural
                self!.unitLabel.text = unit.plural
                self!.unitButton.setTitle(unit.plural, for: .normal)
                self!.perUnitLabel.text = "Nutrition Per \(unit.singular)"
            })
        }
        
        let alert = UIAlertController(title: "Choose unit of measurment", message: nil, preferredStyle: .actionSheet)
        alert.addAction(action(.serving))
        alert.addAction(action(.milligram))
        alert.addAction(action(.gram))
        alert.addAction(action(.ounce))
        alert.addAction(action(.pound))
        alert.addAction(action(.fluidOunce))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        return alert
    }()
    
    func setup(_ context: MeasurementUnitControllerContext) {
        self.context = context
        unitBarButton.isEnabled = context.isEnabled
        unitButton.isEnabled = context.isEnabled
        perUnitLabel.text = "Nutrition Per \(context.unit.singular)"
    }
    
    @IBAction func showUnitMenu() {
        viewController.present(unitPicker, animated: true)
    }
}

class MeasurementValueController: NSObject {
    @IBOutlet weak var scrollController: ScrollController!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var valueRepresentationControl: UISegmentedControl!
    @IBOutlet weak var field: UITextField!
    
    private var context: MeasurementValueControllerContext!
    
    func setup(_ context: MeasurementValueControllerContext) {
        self.context = context
        valueRepresentationControl.selectedSegmentIndex = context.representation.rawValue
        field.inputAccessoryView = toolbar
        switch context.representation {
        case .decimal:  field.text = context.value.to(Float.self).pretty
        case .fraction: field.text = Fraction.decode(from: context.value)?.description
        }
    }
    
    @IBAction func chooseRepresentation(_ sender: UISegmentedControl) {
        context.representation = FoodEntry.MeasurementValueRepresentation(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
}

extension MeasurementValueController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollController.scrollToView(textField)
        if textField.text == "0" {
            textField.text = ""
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        for character in string {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "/": continue
            default: return false
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch context.representation {
        case .decimal:
            if let decimal = Float(textField.text!) {
                context.value = Data(decimal)
                textField.text = decimal.pretty
            } else {
                context.value = Data(Float(0.0))
                textField.text = "0"
            }
        case .fraction:
            if let fraction = Fraction(textField.text!) {
                context.value = fraction.encode()!
                textField.text = fraction.description
            } else {
                context.value = Fraction().encode()!
                textField.text = "0"
            }
        }
    }
}

extension MeasurementUnitController {
    final class DisabledExistingFood {
        private let food: Food
        
        init(_ food: Food) {
            self.food = food
        }
    }
    
    final class EnabledExistingFood {
        private let food: Food
        private let foodChanges: Changes<Food>
        
        init(_ food: Food, _ foodChanges: Changes<Food>) {
            self.food = food
            self.foodChanges = foodChanges
        }
    }
    
    final class NewFood {
        private let food: Food
        
        init(_ food: Food) {
            self.food = food
        }
    }
}

protocol MeasurementUnitControllerContext {
    var isEnabled: Bool { get }
    var unit: Food.MeasurementUnit { get set }
}

extension MeasurementUnitController.DisabledExistingFood: MeasurementUnitControllerContext {
    var isEnabled: Bool {
        return false
    }
    var unit: Food.MeasurementUnit {
        get { return food.measurementUnit }
        set { fatalError() }
    }
}

extension MeasurementUnitController.EnabledExistingFood: MeasurementUnitControllerContext {
    var isEnabled: Bool {
        return true
    }
    var unit: Food.MeasurementUnit {
        get { return food.measurementUnit }
        set {
            foodChanges.insert(change: \Food.measurementUnitRaw)
            food.measurementUnit = newValue
        }
    }
}

extension MeasurementUnitController.NewFood: MeasurementUnitControllerContext {
    var isEnabled: Bool {
        return true
    }
    var unit: Food.MeasurementUnit {
        get { return food.measurementUnit }
        set { food.measurementUnit = newValue }
    }
}

extension MeasurementValueController {
    final class ExistingFoodEntry {
        private let foodEntry: FoodEntry
        private let foodEntryChanges: Changes<FoodEntry>
        
        init(_ foodEntry: FoodEntry, _ foodEntryChanges: Changes<FoodEntry>) {
            self.foodEntry = foodEntry
            self.foodEntryChanges = foodEntryChanges
        }
    }
    
    final class NewFoodEntry {
        private let foodEntry: FoodEntry
        
        init(_ foodEntry: FoodEntry) {
            self.foodEntry = foodEntry
        }
    }
}

protocol MeasurementValueControllerContext {
    var representation: FoodEntry.MeasurementValueRepresentation { get set }
    var value: Data { get set }
}

extension MeasurementValueController.ExistingFoodEntry: MeasurementValueControllerContext {
    var representation: FoodEntry.MeasurementValueRepresentation {
        get { return foodEntry.measurementValueRepresentation }
        set {
            foodEntryChanges.insert(change: \FoodEntry.measurementValueRepresentationRaw)
            foodEntry.measurementValueRepresentation = newValue
        }
    }
    var value: Data {
        get { return foodEntry.measurementValue }
        set {
            foodEntryChanges.insert(change: \FoodEntry.measurementValue)
            foodEntry.measurementValue = newValue
        }
    }
}

extension MeasurementValueController.NewFoodEntry: MeasurementValueControllerContext {
    var representation: FoodEntry.MeasurementValueRepresentation {
        get { return foodEntry.measurementValueRepresentation }
        set { foodEntry.measurementValueRepresentation = newValue }
    }
    var value: Data {
        get { return foodEntry.measurementValue }
        set { foodEntry.measurementValue = newValue }
    }
}

extension Food.MeasurementUnit {
    fileprivate var plural: String {
        switch self {
        case .serving:      return "Servings"
        case .milligram:    return "Milligrams"
        case .gram:         return "Grams"
        case .ounce:        return "Ounces"
        case .pound:        return "Pounds"
        case .fluidOunce:   return "Fluid Ounces"
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
