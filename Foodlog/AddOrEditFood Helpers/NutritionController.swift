//
//  NutritionController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class NutritionController: NSObject {
    @IBOutlet weak var scrollController:                    ScrollController!
    @IBOutlet weak var toolbar:                             UIToolbar!
    @IBOutlet weak var valueRepresentationControl:          UISegmentedControl!
    @IBOutlet weak var defaultNutritionPlaceholderView:     UIView!
    @IBOutlet weak var extendedNutritionToggleButton:       UIButton!
    @IBOutlet weak var extendedNutritionPlaceholderView:    UIView!
    
    private static let completeOrdering: [Int] = {
        let kinds = [
            NutritionKind.calories, .totalFat, .saturatedFat, .transFat, .cholesterol, .sodium, .totalCarbohydrate,
            .dietaryFiber, .sugars, .protein, .biotin, .caffeine, .calcium, .chloride, .chromium, .copper, .folate,
            .iodine, .iron, .magnesium, .manganese, .molybdenum, .monounsaturatedFat, .niacin, .pantothenicAcid,
            .phosphorus, .polyunsaturatedFat, .potassium, .riboflavin, .selenium, .thiamin, .vitaminA, .vitaminB6,
            .vitaminB12, .vitaminC, .vitaminD, .vitaminE, .vitaminK, .zinc
        ]
        return kinds.map { $0.textFieldTag }
    }()
    private static let defaultOrdering: [Int] = {
        let kinds = [
            NutritionKind.calories, .totalFat, .saturatedFat, .transFat, .cholesterol, .sodium, .totalCarbohydrate,
            .dietaryFiber, .sugars, .protein
        ]
        return kinds.map { $0.textFieldTag }
    }()
    private static let extendedOrdering: [Int] = {
        let kinds = [
            NutritionKind.biotin, .caffeine, .calcium, .chloride, .chromium, .copper, .folate, .iodine, .iron,
            .magnesium, .manganese, .molybdenum, .monounsaturatedFat, .niacin, .pantothenicAcid, .phosphorus,
            .polyunsaturatedFat, .potassium, .riboflavin, .selenium, .thiamin, .vitaminA, .vitaminB6, .vitaminB12,
            .vitaminC, .vitaminD, .vitaminE, .vitaminK, .zinc
        ]
        return kinds.map { $0.textFieldTag }
    }()
    private let defaultNutrition = [
        NutritionKind.calories.textFieldTag:            NutrientContext(.calories),
        NutritionKind.totalFat.textFieldTag:            NutrientContext(.totalFat),
        NutritionKind.saturatedFat.textFieldTag:        NutrientContext(.saturatedFat),
        NutritionKind.transFat.textFieldTag:            NutrientContext(.transFat),
        NutritionKind.cholesterol.textFieldTag:         NutrientContext(.cholesterol),
        NutritionKind.sodium.textFieldTag:              NutrientContext(.sodium),
        NutritionKind.totalCarbohydrate.textFieldTag:   NutrientContext(.totalCarbohydrate),
        NutritionKind.dietaryFiber.textFieldTag:        NutrientContext(.dietaryFiber),
        NutritionKind.sugars.textFieldTag:              NutrientContext(.sugars),
        NutritionKind.protein.textFieldTag:             NutrientContext(.protein)
    ]
    private let extendedNutrition = [
        NutritionKind.biotin.textFieldTag:              NutrientContext(.biotin),
        NutritionKind.caffeine.textFieldTag:            NutrientContext(.caffeine),
        NutritionKind.calcium.textFieldTag:             NutrientContext(.calcium),
        NutritionKind.chloride.textFieldTag:            NutrientContext(.chloride),
        NutritionKind.chromium.textFieldTag:            NutrientContext(.chromium),
        NutritionKind.copper.textFieldTag:              NutrientContext(.copper),
        NutritionKind.folate.textFieldTag:              NutrientContext(.folate),
        NutritionKind.iodine.textFieldTag:              NutrientContext(.iodine),
        NutritionKind.iron.textFieldTag:                NutrientContext(.iron),
        NutritionKind.magnesium.textFieldTag:           NutrientContext(.magnesium),
        NutritionKind.manganese.textFieldTag:           NutrientContext(.manganese),
        NutritionKind.molybdenum.textFieldTag:          NutrientContext(.molybdenum),
        NutritionKind.monounsaturatedFat.textFieldTag:  NutrientContext(.monounsaturatedFat),
        NutritionKind.niacin.textFieldTag:              NutrientContext(.niacin),
        NutritionKind.pantothenicAcid.textFieldTag:     NutrientContext(.pantothenicAcid),
        NutritionKind.phosphorus.textFieldTag:          NutrientContext(.phosphorus),
        NutritionKind.polyunsaturatedFat.textFieldTag:  NutrientContext(.polyunsaturatedFat),
        NutritionKind.potassium.textFieldTag:           NutrientContext(.potassium),
        NutritionKind.riboflavin.textFieldTag:          NutrientContext(.riboflavin),
        NutritionKind.selenium.textFieldTag:            NutrientContext(.selenium),
        NutritionKind.thiamin.textFieldTag:             NutrientContext(.thiamin),
        NutritionKind.vitaminA.textFieldTag:            NutrientContext(.vitaminA),
        NutritionKind.vitaminB6.textFieldTag:           NutrientContext(.vitaminB6),
        NutritionKind.vitaminB12.textFieldTag:          NutrientContext(.vitaminB12),
        NutritionKind.vitaminC.textFieldTag:            NutrientContext(.vitaminC),
        NutritionKind.vitaminD.textFieldTag:            NutrientContext(.vitaminD),
        NutritionKind.vitaminE.textFieldTag:            NutrientContext(.vitaminE),
        NutritionKind.vitaminK.textFieldTag:            NutrientContext(.vitaminK),
        NutritionKind.zinc.textFieldTag:                NutrientContext(.zinc)
    ]
    private var activeTextField: UITextField!
    private var context: FoodNutritionControllerContext!
    private var isShowingExtendedNutrition = false
    private lazy var defaultNutritionView =
        NutritionController.makeStackView(for: NutritionController.defaultOrdering.map { defaultNutrition[$0]! },
                                          context: context, textFieldDelegate: self)
    private lazy var extendedNutritionView =
        NutritionController.makeStackView(for: NutritionController.extendedOrdering.map { extendedNutrition[$0]! },
                                          context: context, textFieldDelegate: self)
    
    func setup(_ context: FoodNutritionControllerContext) {
        self.context = context
        defaultNutritionPlaceholderView.embedSubview(defaultNutritionView)
    }
    
    @IBAction func chooseValueRepresentation(_ sender: UISegmentedControl) {
        guard let textField = activeTextField,
            let representation = NutritionKind.ValueRepresentation(segmentIndex: sender.selectedSegmentIndex)
            else { return }
        (defaultNutrition[textField.tag] ?? extendedNutrition[textField.tag]!).representation = representation
    }
    
    @IBAction func toggleExtendedNutrition() {
        isShowingExtendedNutrition = !isShowingExtendedNutrition
        if isShowingExtendedNutrition {
            extendedNutritionToggleButton.setTitle("Show Less", for: .normal)
        } else {
            extendedNutritionToggleButton.setTitle("Show More", for: .normal)
        }
        
        let animation: () -> ()
        if isShowingExtendedNutrition {
            animation = { [extendedNutritionPlaceholderView, extendedNutritionView] in
                extendedNutritionPlaceholderView!.embedSubview(extendedNutritionView)
            }
        } else {
            animation = { [extendedNutritionView] in extendedNutritionView.removeFromSuperview() }
        }
        UIView.transition(with: extendedNutritionPlaceholderView, duration: 0.2, options: .transitionCrossDissolve,
                          animations: animation)
    }
    
    private static func makeStackView(for nutrition: [NutrientContext], context: FoodNutritionControllerContext,
                                      textFieldDelegate: UITextFieldDelegate) -> UIStackView
    {
        func labelAndTextField(nc: NutrientContext) -> UIView {
            let label = UILabel()
            label.text = nc.kind.title
            let field = nc.field
            field.delegate = textFieldDelegate
            field.isEnabled = context.textFieldsAreEnabled
            field.text = context[nc.kind].fullTextFromReal(kind: nc.kind, representation: nc.representation)
            NSLayoutConstraint.activate([field.widthAnchor.constraint(equalToConstant: 125.0)])
            return UIStackView(arrangedSubviews: [label, field])
        }
        
        let stackView = UIStackView(arrangedSubviews: nutrition.map(labelAndTextField))
        stackView.axis = .vertical
        stackView.layoutMargins = .init(top: 4.0, left: 16.0, bottom: 4.0, right: 16.0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 8.0
        return stackView
    }
    
    private func moveToNutritionField(_ calculate: @escaping (Int) -> Int) {
        guard let currentTag = activeTextField?.tag else { return }
        
        func nextTag(ordering: [Int]) -> Int {
            var index = calculate(ordering.index(of: currentTag)!)
            if index < 0 {
                index = ordering.count-1
            } else if index >= ordering.count {
                index = 0
            }
            return ordering[index]
        }
        
        if isShowingExtendedNutrition {
            let tag = nextTag(ordering: NutritionController.completeOrdering)
            activeTextField = (defaultNutrition[tag] ?? extendedNutrition[tag]!).field
        } else {
            let tag = nextTag(ordering: NutritionController.defaultOrdering)
            activeTextField = defaultNutrition[tag]!.field
        }
        activeTextField.becomeFirstResponder()
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

extension NutritionController {
    private class NutrientContext {
        let kind: NutritionKind
        let field: UITextField
        var representation = NutritionKind.ValueRepresentation.real
        
        init(_ kind: NutritionKind) {
            self.kind = kind
            field = UITextField()
            field.borderStyle = .roundedRect
            field.font = .systemFont(ofSize: 14.0)
            field.keyboardType = .decimalPad
            field.tag = kind.textFieldTag
            field.textAlignment = .right
        }
    }
}

extension NutritionController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.inputAccessoryView = toolbar
        activeTextField = textField
        // text_field > horizontal_stack > vertical_stack > placeholder > scroll
        let scrollView = textField.superview!.superview!.superview!.superview!
        scrollController.scroll(to: textField.superview!.convert(textField.frame, to: scrollView))
        
        let nc = defaultNutrition[textField.tag] ?? extendedNutrition[textField.tag]!
        valueRepresentationControl.isEnabled = nc.kind.dailyValueReal != nil
        valueRepresentationControl.selectedSegmentIndex = nc.representation.segmentIndex
        valueRepresentationControl.setTitle(nc.kind.unit.buttonTitle, forSegmentAt: 1)
        textField.text = context[nc.kind].editingText(kind: nc.kind, representation: nc.representation)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        return string.isValidForDecimalOrFractionalInput
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
        let nc = defaultNutrition[textField.tag] ?? extendedNutrition[textField.tag]!
        let value = Float(textField.text!) ?? 0.0
        context[nc.kind] = value.realValue(kind: nc.kind, representation: nc.representation)
        textField.text = value.fullText(kind: nc.kind, representation: nc.representation)
    }
}

extension NutritionController {
    final class Disabled {
        private let food: Food
        
        init(_ food: Food) {
            self.food = food
        }
    }
    
    final class EnabledExistingFood {
        private let changes: Changes<Food>
        private let food: Food
        private let oldFood: Food
        
        init(_ food: Food, _ oldFood: Food, _ changes: Changes<Food>) {
            self.changes = changes
            self.food = food
            self.oldFood = oldFood
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
    var textFieldsAreEnabled: Bool { get }
    subscript(kind: NutritionKind) -> Float { get set }
}

extension NutritionController.Disabled: FoodNutritionControllerContext {
    var textFieldsAreEnabled: Bool {
        return false
    }
    
    subscript(kind: NutritionKind) -> Float {
        get { return food[keyPath: kind.keyPath] }
        set { fatalError() }
    }
}

extension NutritionController.EnabledExistingFood: FoodNutritionControllerContext {
    var textFieldsAreEnabled: Bool {
        return true
    }
    
    subscript(kind: NutritionKind) -> Float {
        get { return food[keyPath: kind.keyPath] }
        set {
            guard newValue != oldFood[keyPath: kind.keyPath] else { return }
            changes.insert(change: kind.keyPath)
            food[keyPath: kind.keyPath] = newValue
        }
    }
}

extension NutritionController.EnabledNewFood: FoodNutritionControllerContext {
    var textFieldsAreEnabled: Bool {
        return true
    }
    
    subscript(kind: NutritionKind) -> Float {
        get { return food[keyPath: kind.keyPath] }
        set { food[keyPath: kind.keyPath] = newValue }
    }
}

extension Float {
    fileprivate func editingText(kind: NutritionKind, representation: NutritionKind.ValueRepresentation) -> String {
        guard self != 0.0 else { return "" }
        switch representation {
        case .percentage:   return dailyValuePercentageFromReal(kind)?.pretty ?? ""
        case .real:         return pretty ?? ""
        }
    }
    
    fileprivate func fullText(kind: NutritionKind, representation: NutritionKind.ValueRepresentation) -> String {
        guard self != 0.0 else { return "0" }
        switch representation {
        case .percentage:
            guard let pretty = pretty else { return "?%" }
            return pretty+"%"
        case .real:
            guard let pretty = pretty else { return "?"+kind.unit.suffix }
            return pretty+kind.unit.suffix
        }
    }
    
    fileprivate func fullTextFromReal(kind: NutritionKind, representation: NutritionKind.ValueRepresentation) -> String {
        guard self != 0.0 else { return "0" }
        switch representation {
        case .percentage:
            guard let pretty = dailyValuePercentageFromReal(kind)?.pretty else { return "?%" }
            return pretty+"%"
        case .real:
            guard let pretty = pretty else { return "?"+kind.unit.suffix }
            return pretty+kind.unit.suffix
        }
    }
    
    fileprivate func realValue(kind: NutritionKind, representation: NutritionKind.ValueRepresentation) -> Float {
        switch representation {
        case .percentage:   return dailyValueRealFromPercentage(kind) ?? 0.0
        case .real:         return self
        }
    }
}

extension NutritionKind {
    fileprivate var textFieldTag: Int {
        switch self {
        case .biotin:               return 0
        case .caffeine:             return 1
        case .calcium:              return 2
        case .calories:             return 3
        case .chloride:             return 4
        case .cholesterol:          return 5
        case .chromium:             return 6
        case .copper:               return 7
        case .dietaryFiber:         return 8
        case .folate:               return 9
        case .iodine:               return 10
        case .iron:                 return 11
        case .magnesium:            return 12
        case .manganese:            return 13
        case .molybdenum:           return 14
        case .monounsaturatedFat:   return 15
        case .niacin:               return 16
        case .pantothenicAcid:      return 17
        case .phosphorus:           return 18
        case .polyunsaturatedFat:   return 19
        case .potassium:            return 20
        case .protein:              return 21
        case .riboflavin:           return 22
        case .saturatedFat:         return 23
        case .selenium:             return 24
        case .sodium:               return 25
        case .sugars:               return 26
        case .thiamin:              return 27
        case .totalCarbohydrate:    return 28
        case .totalFat:             return 29
        case .transFat:             return 30
        case .vitaminA:             return 31
        case .vitaminB6:            return 32
        case .vitaminB12:           return 33
        case .vitaminC:             return 34
        case .vitaminD:             return 35
        case .vitaminE:             return 36
        case .vitaminK:             return 37
        case .zinc:                 return 38
        }
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

extension NutritionKind.ValueRepresentation {
    fileprivate var segmentIndex: Int {
        switch self {
        case .percentage:   return 0
        case .real:         return 1
        }
    }
    
    fileprivate init?(segmentIndex: Int) {
        switch segmentIndex {
        case 0:     self = .percentage
        case 1:     self = .real
        default:    return nil
        }
    }
}
