//
//  ServingSizeController.swift
//  Foodlog
//
//  Created by David on 6/1/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class ServingSizeController: NSObject {
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var unitBarButton: UIBarButtonItem!
    
    var field: UITextField!
    private var context: ServingSizeControllerContext!
    private lazy var unitPicker: UIAlertController = {
        let alert = UIAlertController(title: "Choose unit of measurement", message: nil, preferredStyle: .actionSheet)
        for unit in [Food.Unit.none, .gram, .milligram, .ounce, .milliliter, .fluidOunce] {
            alert.addAction(UIAlertAction(title: unit.buttonTitle, style: .default, handler: { [weak self] _ in
                self!.context.unit = unit
                self!.field.configureForFoodUnit(unit)
                self!.unitBarButton.title = unit.buttonTitle
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        return alert
    }()
    
    func setup(_ context: ServingSizeControllerContext) {
        self.context = context
        field.configureForFoodUnit(context.unit)
        field.delegate = self
        field.inputAccessoryView = toolbar
        if context.unit != .none, let text = context.servingSize.pretty {
            field.text = text + context.unit.suffix
        }
        unitBarButton.title = context.unit.buttonTitle
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
    
    @IBAction func showUnitMenu() {
        context.presentUnitMenu(unitPicker)
    }
}

extension ServingSizeController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if context.servingSize == 0.0 {
            textField.text = ""
        } else {
            textField.text = context.servingSize.pretty
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        return string.isValidForDecimalOrFractionalInput
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if context.unit != .none, let decimal = Float(textField.text!), let text = decimal.pretty {
            context.servingSize = decimal
            textField.text = text + context.unit.suffix
        } else {
            context.servingSize = 0.0
            context.unit = .none
            textField.text = nil
        }
    }
}

extension ServingSizeController {
    final class ExistingFood {
        private let changes: Changes<Food>
        private let food: Food
        private weak var viewController: UIViewController!
        
        init(_ food: Food, _ changes: Changes<Food>, _ viewController: UIViewController) {
            self.food = food
            self.changes = changes
            self.viewController = viewController
        }
    }
    
    final class NewFood {
        private let food: Food
        private weak var viewController: UIViewController!
        
        init(_ food: Food, _ viewController: UIViewController) {
            self.food = food
            self.viewController = viewController
        }
    }
}

protocol ServingSizeControllerContext {
    var servingSize: Float { get set }
    var unit: Food.Unit { get set }
    func presentUnitMenu(_ menu: UIAlertController)
}

extension ServingSizeController.ExistingFood: ServingSizeControllerContext {
    var servingSize: Float {
        get { return food.servingSize }
        set {
            changes.insert(change: \Food.servingSize)
            food.servingSize = newValue
        }
    }
    var unit: Food.Unit {
        get { return food.servingSizeUnit }
        set {
            changes.insert(change: \Food.servingSizeUnitRaw)
            food.servingSizeUnit = newValue
        }
    }
    
    func presentUnitMenu(_ menu: UIAlertController) {
        viewController.present(menu, animated: true)
    }
}

extension ServingSizeController.NewFood: ServingSizeControllerContext {
    var servingSize: Float {
        get { return food.servingSize }
        set { food.servingSize = newValue }
    }
    var unit: Food.Unit {
        get { return food.servingSizeUnit }
        set { food.servingSizeUnit = newValue }
    }
    
    func presentUnitMenu(_ menu: UIAlertController) {
        viewController.present(menu, animated: true)
    }
}

extension Food.Unit {
    fileprivate var buttonTitle: String {
        switch self {
        case .none:         return "None"
        case .gram:         return "Grams"
        case .milligram:    return "Milligrams"
        case .ounce:        return "Ounces"
        case .milliliter:   return "Milliliters"
        case .fluidOunce:   return "Fluid Ounces"
        }
    }
}

extension UITextField {
    fileprivate func configureForFoodUnit(_ unit: Food.Unit) {
        switch unit {
        case .none:
            if inputView == nil {
                text = ""
                inputView = UIView()
                reloadInputViews()
            }
        default:
            if inputView != nil {
                inputView = nil
                keyboardType = .decimalPad
                reloadInputViews()
            }
        }
    }
}
