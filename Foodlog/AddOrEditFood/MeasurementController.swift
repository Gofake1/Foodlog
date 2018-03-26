//
//  MeasurementController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class MeasurementController: NSObject {
    @IBOutlet weak var scrollController: ScrollController!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var valueRepresentationControl: UISegmentedControl!
    @IBOutlet weak var representationButton: UIButton!
    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var perRepresentationLabel: UILabel!
    
    private var context: MeasurementControllerContext!
    private lazy var representationPicker: UIAlertController = {
        func action(_ representation: Food.MeasurementRepresentation) -> UIAlertAction {
            return UIAlertAction(title: representation.plural, style: .default, handler: { [weak self] (_) in
                self!.context.measurementRepresentation = representation
                self!.representationButton.setTitle(representation.plural, for: .normal)
                self!.perRepresentationLabel.text = "Information Per \(representation.singular)"
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
    
    func setup(_ context: MeasurementControllerContext) {
        self.context = context
        if context.hasMeasurementValue {
            valueRepresentationControl.selectedSegmentIndex = context.measurementValueRepresentation.rawValue
            representationButton.setTitle(context.measurementRepresentation.plural, for: .normal)
            representationButton.isEnabled = context.canChangeRepresentation
            field.inputAccessoryView = toolbar
            switch context.measurementValueRepresentation {
            case .decimal:  field.text = context.measurementValue.to(Float.self).pretty
            case .fraction: field.text = (Fraction.decode(from: context.measurementValue)!).description
            }
        }
        perRepresentationLabel.text = "Information Per \(context.measurementRepresentation.singular)"
    }
    
    @IBAction func chooseValueRepresentation(_ sender: UISegmentedControl) {
        context.measurementValueRepresentation = FoodEntry.MeasurementValueRepresentation(rawValue:
            sender.selectedSegmentIndex)!
    }
    
    @IBAction func showRepresentationsMenu() {
        UIApplication.shared.keyWindow?.rootViewController?.present(representationPicker, animated: true)
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
}

extension MeasurementController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollController.scrollToView(textField)
        if textField.text == "0" {
            textField.text = ""
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        for character in string {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "/": continue
            default: return false
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch context.measurementValueRepresentation {
        case .decimal:
            if let decimal = Float(textField.text!) {
                context.measurementValue = Data(decimal)
                textField.text = decimal.pretty
            } else {
                context.measurementValue = Data(Float(0.0))
                textField.text = "0"
            }
        case .fraction:
            if let fraction = Fraction(textField.text!) {
                context.measurementValue = fraction.encode()!
                textField.text = fraction.description
            } else {
                context.measurementValue = Fraction().encode()!
                textField.text = "0"
            }
        }
    }
}

protocol MeasurementControllerContext {
    var canChangeRepresentation: Bool { get }
    var hasMeasurementValue: Bool { get }
    var measurementValue: Data { get set }
    var measurementValueRepresentation: FoodEntry.MeasurementValueRepresentation { get set }
    var measurementRepresentation: Food.MeasurementRepresentation { get set }
}

final class AddEntryForExistingFoodMeasurementControllerContext: MeasurementControllerContext {
    var canChangeRepresentation: Bool {
        return false
    }
    var hasMeasurementValue: Bool {
        return true
    }
    var measurementValue: Data {
        get { return foodEntry.measurementValue }
        set { foodEntry.measurementValue = newValue }
    }
    var measurementValueRepresentation: FoodEntry.MeasurementValueRepresentation {
        get { return foodEntry.measurementValueRepresentation }
        set { foodEntry.measurementValueRepresentationRaw = newValue.rawValue}
    }
    var measurementRepresentation: Food.MeasurementRepresentation {
        get { return foodEntry.food!.measurementRepresentation }
        set { fatalError() }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
}

final class AddEntryForNewFoodMeasurementControllerContext: MeasurementControllerContext {
    var canChangeRepresentation: Bool {
        return true
    }
    var hasMeasurementValue: Bool {
        return true
    }
    var measurementValue: Data {
        get { return foodEntry.measurementValue }
        set { foodEntry.measurementValue = newValue }
    }
    var measurementValueRepresentation: FoodEntry.MeasurementValueRepresentation {
        get { return foodEntry.measurementValueRepresentation }
        set { foodEntry.measurementValueRepresentationRaw = newValue.rawValue }
    }
    var measurementRepresentation: Food.MeasurementRepresentation {
        get { return foodEntry.food!.measurementRepresentation }
        set { foodEntry.food!.measurementRepresentationRaw = newValue.rawValue }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
}

final class EditFoodMeasurementControllerContext: MeasurementControllerContext {
    var canChangeRepresentation: Bool {
        return false
    }
    var hasMeasurementValue: Bool {
        return false
    }
    var measurementValue: Data {
        get { fatalError() }
        set { fatalError() }
    }
    var measurementValueRepresentation: FoodEntry.MeasurementValueRepresentation {
        get { fatalError() }
        set { fatalError() }
    }
    var measurementRepresentation: Food.MeasurementRepresentation {
        get { return food.measurementRepresentation }
        set {
            foodInfoChanged.value ||= newValue != food.measurementRepresentation
            food.measurementRepresentationRaw = newValue.rawValue
        }
    }
    private let food: Food
    private let foodInfoChanged: Ref<Bool>
    
    init(_ food: Food, _ foodInfoChanged: Ref<Bool>) {
        self.food = food
        self.foodInfoChanged = foodInfoChanged
    }
}

final class EditFoodEntryMeasurementControllerContext: MeasurementControllerContext {
    var canChangeRepresentation: Bool {
        return true
    }
    var hasMeasurementValue: Bool {
        return true
    }
    var measurementValue: Data {
        get { return foodEntry.measurementValue }
        set { foodEntry.measurementValue = newValue }
    }
    var measurementValueRepresentation: FoodEntry.MeasurementValueRepresentation {
        get { return foodEntry.measurementValueRepresentation }
        set { foodEntry.measurementValueRepresentationRaw = newValue.rawValue }
    }
    var measurementRepresentation: Food.MeasurementRepresentation {
        get { return foodEntry.food!.measurementRepresentation }
        set {
            foodInfoChanged.value ||= newValue != foodEntry.food!.measurementRepresentation
            foodEntry.food!.measurementRepresentationRaw = newValue.rawValue
        }
    }
    private let foodEntry: FoodEntry
    private var foodInfoChanged: Ref<Bool>
    
    init(_ foodEntry: FoodEntry, _ foodInfoChanged: Ref<Bool>) {
        self.foodEntry = foodEntry
        self.foodInfoChanged = foodInfoChanged
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
