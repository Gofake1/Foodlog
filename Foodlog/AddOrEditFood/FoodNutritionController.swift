//
//  FoodNutritionController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class FoodNutritionController: NSObject {
    @IBOutlet weak var addOrEditVC:                 AddOrEditFoodViewController!
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
    
    private var calories: Float? {
        get { return addOrEditVC.foodEntry.food?.calories }
        set { addOrEditVC.foodEntry.food?.calories = newValue! }
    }
    private var totalFat: Float? {
        get { return addOrEditVC.foodEntry.food?.totalFat}
        set { addOrEditVC.foodEntry.food?.totalFat = newValue! }
    }
    private var saturatedFat: Float? {
        get { return addOrEditVC.foodEntry.food?.saturatedFat }
        set { addOrEditVC.foodEntry.food?.saturatedFat = newValue!}
    }
    private var monounsaruratedFat: Float? {
        get { return addOrEditVC.foodEntry.food?.monounsaturatedFat }
        set { addOrEditVC.foodEntry.food?.monounsaturatedFat = newValue!}
    }
    private var polyunsaturatedFat: Float? {
        get { return addOrEditVC.foodEntry.food?.polyunsaturatedFat }
        set { addOrEditVC.foodEntry.food?.polyunsaturatedFat = newValue!}
    }
    private var transFat: Float? {
        get { return addOrEditVC.foodEntry.food?.transFat }
        set { addOrEditVC.foodEntry.food?.transFat = newValue!}
    }
    private var cholesterol: Float? {
        get { return addOrEditVC.foodEntry.food?.cholesterol }
        set { addOrEditVC.foodEntry.food?.cholesterol = newValue!}
    }
    private var sodium: Float? {
        get { return addOrEditVC.foodEntry.food?.sodium }
        set { addOrEditVC.foodEntry.food?.sodium = newValue!}
    }
    private var totalCarbohydrate: Float? {
        get { return addOrEditVC.foodEntry.food?.totalCarbohydrate }
        set { addOrEditVC.foodEntry.food?.totalCarbohydrate = newValue!}
    }
    private var dietaryFiber: Float? {
        get { return addOrEditVC.foodEntry.food?.dietaryFiber }
        set { addOrEditVC.foodEntry.food?.dietaryFiber = newValue!}
    }
    private var sugars: Float? {
        get { return addOrEditVC.foodEntry.food?.sugars }
        set { addOrEditVC.foodEntry.food?.sugars = newValue!}
    }
    private var protein: Float? {
        get { return addOrEditVC.foodEntry.food?.protein }
        set { addOrEditVC.foodEntry.food?.protein = newValue!}
    }
    private var vitaminA: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminA }
        set { addOrEditVC.foodEntry.food?.vitaminA = newValue!}
    }
    private var vitaminB6: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminB6 }
        set { addOrEditVC.foodEntry.food?.vitaminB6 = newValue!}
    }
    private var vitaminB12: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminB12 }
        set { addOrEditVC.foodEntry.food?.vitaminB12 = newValue!}
    }
    private var vitaminC: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminC }
        set { addOrEditVC.foodEntry.food?.vitaminC = newValue!}
    }
    private var vitaminD: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminD }
        set { addOrEditVC.foodEntry.food?.vitaminD = newValue!}
    }
    private var vitaminE: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminE }
        set { addOrEditVC.foodEntry.food?.vitaminE = newValue!}
    }
    private var vitaminK: Float? {
        get { return addOrEditVC.foodEntry.food?.vitaminK }
        set { addOrEditVC.foodEntry.food?.vitaminK = newValue!}
    }
    private var calcium: Float? {
        get { return addOrEditVC.foodEntry.food?.calcium }
        set { addOrEditVC.foodEntry.food?.calcium = newValue!}
    }
    private var iron: Float? {
        get { return addOrEditVC.foodEntry.food?.iron }
        set { addOrEditVC.foodEntry.food?.iron = newValue!}
    }
    private var magnesium: Float? {
        get { return addOrEditVC.foodEntry.food?.magnesium }
        set { addOrEditVC.foodEntry.food?.magnesium = newValue!}
    }
    private var potassium: Float? {
        get { return addOrEditVC.foodEntry.food?.potassium }
        set { addOrEditVC.foodEntry.food?.potassium = newValue!}
    }
    typealias Info = (field: UITextField, get: () -> Float?, set: (Float) -> (), kind: NutritionKind,
        representation: NutritionKind.ValueRepresentation)
    private lazy var fields: [Int: Info] = {
        return [
            0:  Info(caloriesField, { [weak self] in return self?.calories },
                     { [weak self] in self?.calories = $0 }, .calories, .real),
            1:  Info(totalFatField, { [weak self] in return self?.totalFat },
                     { [weak self] in self?.totalFat = $0 }, .totalFat, .percentage),
            2:  Info(saturatedFatField, { [weak self] in return self?.saturatedFat },
                     { [weak self] in self?.saturatedFat = $0 }, .saturatedFat, .percentage),
            3:  Info(monounsaturatedFatField, { [weak self] in return self?.monounsaruratedFat },
                     { [weak self] in self?.monounsaruratedFat = $0 }, .monounsaturatedFat, .real),
            4:  Info(polyunsaturatedFatField, { [weak self] in return self?.polyunsaturatedFat },
                     { [weak self] in self?.polyunsaturatedFat = $0 }, .polyunsaturatedFat, .real),
            5:  Info(transFatField, { [weak self] in return self?.transFat },
                     { [weak self] in self?.transFat = $0 }, .transFat, .real),
            6:  Info(cholesterolField, { [weak self] in return self?.cholesterol },
                     { [weak self] in self?.cholesterol = $0 }, .cholesterol, .percentage),
            7:  Info(sodiumField, { [weak self] in return self?.sodium },
                     { [weak self] in self?.sodium = $0 }, .sodium, .percentage),
            8:  Info(totalCarbohydrateField, { [weak self] in return self?.totalCarbohydrate },
                     { [weak self] in self?.totalCarbohydrate = $0 }, .totalCarbohydrate, .percentage),
            9:  Info(dietaryFiberField, { [weak self] in return self?.dietaryFiber },
                     { [weak self] in self?.dietaryFiber = $0 }, .dietaryFiber, .percentage),
            10: Info(sugarsField, { [weak self] in return self?.sugars },
                     { [weak self] in self?.sugars = $0 }, .sugars, .real),
            11: Info(proteinField, { [weak self] in return self?.protein },
                     { [weak self] in self?.protein = $0 }, .protein, .percentage),
            12: Info(vitaminAField, { [weak self] in return self?.vitaminA },
                     { [weak self] in self?.vitaminA = $0 }, .vitaminA, .percentage),
            13: Info(vitaminB6Field, { [weak self] in return self?.vitaminB6 },
                     { [weak self] in self?.vitaminB6 = $0 }, .vitaminB6, .percentage),
            14: Info(vitaminB12Field, { [weak self] in return self?.vitaminB12 },
                     { [weak self] in self?.vitaminB12 = $0 }, .vitaminB12, .percentage),
            15: Info(vitaminCField, { [weak self] in return self?.vitaminC },
                     { [weak self] in self?.vitaminC = $0 }, .vitaminC, .percentage),
            16: Info(vitaminDField, { [weak self] in return self?.vitaminD },
                     { [weak self] in self?.vitaminD = $0 }, .vitaminD, .percentage),
            17: Info(vitaminEField, { [weak self] in return self?.vitaminE },
                     { [weak self] in self?.vitaminE = $0 }, .vitaminE, .percentage),
            18: Info(vitaminKField, { [weak self] in return self?.vitaminK },
                     { [weak self] in self?.vitaminK = $0 }, .vitaminK, .percentage),
            19: Info(calciumField, { [weak self] in return self?.calcium },
                     { [weak self] in self?.calcium = $0 }, .calcium, .percentage),
            20: Info(ironField, { [weak self] in return self?.iron },
                     { [weak self] in self?.iron = $0 }, .iron, .percentage),
            21: Info(magnesiumField, { [weak self] in return self?.magnesium },
                     { [weak self] in self?.magnesium = $0 }, .magnesium, .percentage),
            22: Info(potassiumField, { [weak self] in return self?.potassium },
                     { [weak self] in self?.potassium = $0 }, .potassium, .percentage),
        ]
    }()
    
    func setup(_ mode: AddOrEditFoodViewController.Mode) {
        let isEnabled = (mode == .addNewFood || mode == .editExistingFood)
        fields.forEach {
            $1.field.isEnabled = isEnabled
            $1.field.inputAccessoryView = toolbar
            
            guard let value = $1.get() else { $1.field.text = "?"; return }
            guard value != 0.0 else { $1.field.text = "0"; return }
            switch $1.representation {
            case .percentage:
                guard let pretty = value.dailyValuePercentageFromReal($1.kind)?.pretty
                    else { $1.field.text = "?%"; return }
                $1.field.text = pretty+"%"
            case .real:
                guard let pretty = value.pretty else { $1.field.text = "?"+$1.kind.unit.short; return }
                $1.field.text = pretty+$1.kind.unit.short
            }
        }
    }
    
    @IBAction func chooseValueRepresentation(_ sender: UISegmentedControl) {
        guard let textField = addOrEditVC.activeNutritionField else { return }
        fields[textField.tag]?.representation = NutritionKind.ValueRepresentation(rawValue: sender.selectedSegmentIndex)!
    }
    
    private func moveToNutritionField(_ calculate: (Int) -> Int) {
        guard let currentField = addOrEditVC.activeNutritionField else { return }
        var index = calculate(currentField.tag)
        if index < 0 {
            index = fields.count-1
        } else if index >= fields.count {
            index = 0
        }
        fields[index]?.field.becomeFirstResponder()
    }
    
    @IBAction func moveToPreviousNutritionField() {
        moveToNutritionField { $0-1 }
    }
    
    @IBAction func moveToNextNutritionField() {
        moveToNutritionField { $0+1 }
    }
    
    @IBAction func doneEditing() {
        addOrEditVC.activeNutritionField?.resignFirstResponder()
    }
}

extension FoodNutritionController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        addOrEditVC.activeNutritionField = textField
        guard let fieldInfo = fields[textField.tag] else { return }
        valueRepresentationControl.selectedSegmentIndex = fieldInfo.representation.rawValue
        valueRepresentationControl.setTitle(fieldInfo.kind.unit.buttonTitle, forSegmentAt: 1)
        if let value = fieldInfo.get() {
            if value == 0.0 {
                textField.text = ""
            } else {
                switch fieldInfo.representation {
                case .percentage:
                    textField.text = value.dailyValuePercentageFromReal(fieldInfo.kind)?.pretty
                case .real:
                    textField.text = value.pretty
                }
            }
        } else {
            textField.text = ""
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
        addOrEditVC.activeNutritionField = nil
        guard let set = fields[textField.tag]?.set,
            let representation = fields[textField.tag]?.representation,
            let kind = fields[textField.tag]?.kind
            else { return }
        let value = Float(textField.text!) ?? 0.0
        let realValue: Float
        switch representation {
        case .percentage:   realValue = value.dailyValueRealFromPercentage(kind) ?? 0.0
        case .real:         realValue = value
        }
        if let oldValue = fields[textField.tag]?.get() {
            set(realValue)
            addOrEditVC.userChangedFoodInfo &&= value == oldValue
        } else {
            set(realValue)
            addOrEditVC.userChangedFoodInfo &&= true
        }
        if value == 0.0 {
            textField.text = "0"
        } else {
            guard let pretty = value.pretty else { return }
            switch representation {
            case .percentage:   textField.text = pretty+"%"
            case .real:         textField.text = pretty+kind.unit.short
            }
        }
    }
}

extension NutritionKind.Unit {
    var buttonTitle: String {
        switch self {
        case .calorie:      return "kcal"
        case .gram:         return "g"
        case .milligram:    return "mg"
        case .microgram:    return "mcg"
        }
    }
}
