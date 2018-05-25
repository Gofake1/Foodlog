//
//  FoodNutritionController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

// TODO: User customizable UI
class FoodNutritionController: NSObject {
    private typealias Info = (field: UITextField, kind: NutritionKind, representation: NutritionKind.ValueRepresentation)
    
    @IBOutlet weak var scrollController:            ScrollController!
    @IBOutlet weak var toolbar:                     UIToolbar!
    @IBOutlet weak var valueRepresentationControl:  UISegmentedControl!
    @IBOutlet weak var caloriesField:               UITextField!
    @IBOutlet weak var totalFatField:               UITextField!
    @IBOutlet weak var saturatedFatField:           UITextField!
    @IBOutlet weak var monounsaturatedFatField:     UITextField!
    @IBOutlet weak var polyunsaturatedFatField:     UITextField!
    @IBOutlet weak var transFatField:               UITextField!
    @IBOutlet weak var cholesterolField:            UITextField!
    @IBOutlet weak var sodiumField:                 UITextField!
    @IBOutlet weak var totalCarbohydrateField:      UITextField!
    @IBOutlet weak var dietaryFiberField:           UITextField!
    @IBOutlet weak var sugarsField:                 UITextField!
    @IBOutlet weak var proteinField:                UITextField!
    @IBOutlet weak var vitaminAField:               UITextField!
    @IBOutlet weak var vitaminB6Field:              UITextField!
    @IBOutlet weak var vitaminB12Field:             UITextField!
    @IBOutlet weak var vitaminCField:               UITextField!
    @IBOutlet weak var vitaminDField:               UITextField!
    @IBOutlet weak var vitaminEField:               UITextField!
    @IBOutlet weak var vitaminKField:               UITextField!
    @IBOutlet weak var calciumField:                UITextField!
    @IBOutlet weak var ironField:                   UITextField!
    @IBOutlet weak var magnesiumField:              UITextField!
    @IBOutlet weak var potassiumField:              UITextField!
    
    private lazy var fields = [
        0:  Info(caloriesField, .calories, .real),
        1:  Info(totalFatField, .totalFat, .real),
        2:  Info(saturatedFatField, .saturatedFat, .real),
        3:  Info(monounsaturatedFatField, .monounsaturatedFat, .real),
        4:  Info(polyunsaturatedFatField, .polyunsaturatedFat, .real),
        5:  Info(transFatField, .transFat, .real),
        6:  Info(cholesterolField, .cholesterol, .real),
        7:  Info(sodiumField, .sodium, .real),
        8:  Info(totalCarbohydrateField, .totalCarbohydrate, .real),
        9:  Info(dietaryFiberField, .dietaryFiber, .real),
        10: Info(sugarsField, .sugars, .real),
        11: Info(proteinField, .protein, .real),
        12: Info(vitaminAField, .vitaminA, .percentage),
        13: Info(vitaminB6Field, .vitaminB6, .percentage),
        14: Info(vitaminB12Field, .vitaminB12, .percentage),
        15: Info(vitaminCField, .vitaminC, .percentage),
        16: Info(vitaminDField, .vitaminD, .percentage),
        17: Info(vitaminEField, .vitaminE, .percentage),
        18: Info(vitaminKField, .vitaminK, .percentage),
        19: Info(calciumField, .calcium, .percentage),
        20: Info(ironField, .iron, .percentage),
        21: Info(magnesiumField, .magnesium, .percentage),
        22: Info(potassiumField, .potassium, .percentage)
    ]
    private var activeTextField: UITextField!
    private var context: FoodNutritionControllerContext!
    
    func setup(_ context: FoodNutritionControllerContext) {
        self.context = context
        fields.values.forEach { (field, kind, representation) in
            field.isEnabled = context.enableFields
            field.inputAccessoryView = toolbar
            
            let value = context.value(for: kind)
            guard value != 0.0 else { field.text = "0"; return }
            switch representation {
            case .percentage:
                guard let pretty = value.dailyValuePercentageFromReal(kind)?.pretty
                    else { field.text = "?%"; return }
                field.text = pretty+"%"
            case .real:
                guard let pretty = value.pretty else { field.text = "?"+kind.unit.suffix; return }
                field.text = pretty+kind.unit.suffix
            }
        }
    }
    
    @IBAction func chooseValueRepresentation(_ sender: UISegmentedControl) {
        guard let textField = activeTextField,
            let representation = NutritionKind.ValueRepresentation(rawValue: sender.selectedSegmentIndex)
            else { return }
        fields[textField.tag]?.representation = representation
    }
    
    private func moveToNutritionField(_ calculate: (Int) -> Int) {
        guard let currentField = activeTextField else { return }
        var index = calculate(currentField.tag)
        if index < 0 {
            index = fields.count-1
        } else if index >= fields.count {
            index = 0
        }
        activeTextField = fields[index]!.field
        activeTextField.becomeFirstResponder()
        scrollController.scrollToView(activeTextField)
    }
    
    @IBAction func moveToPreviousNutritionField() {
        moveToNutritionField { $0-1 }
    }
    
    @IBAction func moveToNextNutritionField() {
        moveToNutritionField { $0+1 }
    }
    
    @IBAction func doneEditing() {
        activeTextField.resignFirstResponder()
    }
}

extension FoodNutritionController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        scrollController.scrollToView(textField)
        guard let info = fields[textField.tag] else { return }
        valueRepresentationControl.isEnabled = info.kind.dailyValueReal != nil
        valueRepresentationControl.selectedSegmentIndex = info.representation.rawValue
        valueRepresentationControl.setTitle(info.kind.unit.buttonTitle, forSegmentAt: 1)
        let value = context.value(for: info.kind)
        if value == 0.0 {
            textField.text = ""
        } else {
            switch info.representation {
            case .percentage:
                textField.text = value.dailyValuePercentageFromReal(info.kind)?.pretty
            case .real:
                textField.text = value.pretty
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        for character in string {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",": continue
            default: return false
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
        guard let info = fields[textField.tag] else { return }
        let value = Float(textField.text!) ?? 0.0
        let realValue: Float
        switch info.representation {
        case .percentage:   realValue = value.dailyValueRealFromPercentage(info.kind) ?? 0.0
        case .real:         realValue = value
        }
        context.set(kind: info.kind, to: realValue)
        if value == 0.0 {
            textField.text = "0"
        } else {
            guard let pretty = value.pretty else { return }
            switch info.representation {
            case .percentage:   textField.text = pretty+"%"
            case .real:         textField.text = pretty+info.kind.unit.suffix
            }
        }
    }
}

extension FoodNutritionController {
    final class Disabled {
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
    
    final class EnabledNewFood {
        private let food: Food
        
        init(_ food: Food) {
            self.food = food
        }
    }
}

protocol FoodNutritionControllerContext {
    var enableFields: Bool { get }
    func set(kind: NutritionKind, to value: Float)
    func value(for kind: NutritionKind) -> Float
}

extension FoodNutritionController.Disabled: FoodNutritionControllerContext {
    var enableFields: Bool {
        return false
    }
    
    func set(kind: NutritionKind, to value: Float) {
        fatalError()
    }
    
    func value(for kind: NutritionKind) -> Float {
        return food[keyPath: kind.keyPath]
    }
}

extension FoodNutritionController.EnabledExistingFood: FoodNutritionControllerContext {
    var enableFields: Bool {
        return true
    }
    
    func set(kind: NutritionKind, to newValue: Float) {
        foodChanges.insert(change: kind.keyPath)
        food[keyPath: kind.keyPath] = newValue
    }
    
    func value(for kind: NutritionKind) -> Float {
        return food[keyPath: kind.keyPath]
    }
}

extension FoodNutritionController.EnabledNewFood: FoodNutritionControllerContext {
    var enableFields: Bool {
        return true
    }
    
    func set(kind: NutritionKind, to value: Float) {
        food[keyPath: kind.keyPath] = value
    }
    
    func value(for kind: NutritionKind) -> Float {
        return food[keyPath: kind.keyPath]
    }
}

extension NutritionKind.Unit {
    fileprivate var buttonTitle: String {
        switch self {
        case .calorie:      return "kcal"
        case .gram:         return "g"
        case .milligram:    return "mg"
        case .microgram:    return "mcg"
        }
    }
}
