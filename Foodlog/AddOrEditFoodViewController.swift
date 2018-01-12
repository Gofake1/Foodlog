//
//  AddFoodViewController.swift
//  Foodlog
//
//  Created by David on 12/30/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

private let _dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .short
    return df
}()

private let _datePicker: UIDatePicker = {
    let dp = UIDatePicker()
    dp.datePickerMode = .dateAndTime
    return dp
}()

class AddOrEditFoodViewController: PulleyDrawerViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var servingsField: UITextField!
    @IBOutlet weak var caloriesField: UITextField!
    @IBOutlet weak var totalFatField: UITextField!
    @IBOutlet weak var saturatedFatField: UITextField!
    @IBOutlet weak var monounsaturatedFatField: UITextField!
    @IBOutlet weak var polyunsaturatedFatField: UITextField!
    @IBOutlet weak var transFatField: UITextField!
    @IBOutlet weak var cholesterolField: UITextField!
    @IBOutlet weak var sodiumField: UITextField!
    @IBOutlet weak var totalCarbohydrateField: UITextField!
    @IBOutlet weak var dietaryFiberField: UITextField!
    @IBOutlet weak var sugarsField: UITextField!
    @IBOutlet weak var proteinField: UITextField!
    @IBOutlet weak var vitaminAField: UITextField!
    @IBOutlet weak var vitaminB6Field: UITextField!
    @IBOutlet weak var vitaminB12Field: UITextField!
    @IBOutlet weak var vitaminCField: UITextField!
    @IBOutlet weak var vitaminDField: UITextField!
    @IBOutlet weak var vitaminEField: UITextField!
    @IBOutlet weak var vitaminKField: UITextField!
    @IBOutlet weak var calciumField: UITextField!
    @IBOutlet weak var ironField: UITextField!
    @IBOutlet var nutritionInfoFields: [UITextField]!
    
    var food: Food!
    private weak var activeTextField: UITextField?
    
    override func viewDidLoad() {
        foodNameLabel.text              = food.name
        caloriesField.text              = String(food.calcium)
        totalFatField.text              = String(food.totalFat)
        saturatedFatField.text          = String(food.saturatedFat)
        monounsaturatedFatField.text    = String(food.monounsaturatedFat)
        polyunsaturatedFatField.text    = String(food.polyunsaturatedFat)
        transFatField.text              = String(food.transFat)
        cholesterolField.text           = String(food.cholesterol)
        sodiumField.text                = String(food.sodium)
        totalCarbohydrateField.text     = String(food.totalCarbohydrate)
        dietaryFiberField.text          = String(food.dietaryFiber)
        sugarsField.text                = String(food.sugars)
        proteinField.text               = String(food.protein)
        vitaminAField.text              = String(food.vitaminA)
        vitaminB6Field.text             = String(food.vitaminB6)
        vitaminB12Field.text            = String(food.vitaminB12)
        vitaminCField.text              = String(food.vitaminC)
        vitaminDField.text              = String(food.vitaminD)
        vitaminEField.text              = String(food.vitaminE)
        vitaminKField.text              = String(food.vitaminK)
        calciumField.text               = String(food.calcium)
        ironField.text                  = String(food.iron)
        
        dateField.text = _dateFormatter.string(from: Date().roundedToNearestHalfHour)
        _datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        dateField.inputView = _datePicker
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        dateField.text = _dateFormatter.string(from: sender.date)
    }
    
    @objc func keyboardWasShown(_ aNotifcation: NSNotification) {
        guard let userInfo = aNotifcation.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        
        // Workaround: Text field frame is translated down by Pulley
        let fixedTextFieldFrame = view.superview!.convert(activeTextField!.frame, to: nil)
        // Workaround: `scrollRectToVisible` ignores `rect` parameter
        // https://stackoverflow.com/questions/21434651/uiscrollview-scrollrecttovisibleanimated-not-taking-rect-into-account-on-ios7
        DispatchQueue.main.async { [weak self] in
            self?.scrollView.scrollRectToVisible(fixedTextFieldFrame, animated: true)
        }
    }
    
    @objc func keyboardWillBeHidden(_ aNotification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @IBAction func addFoodToLog() {
        let foodEntry = FoodEntry()
        foodEntry.food = food
        do {
            try Realm().add(foodEntry)
        } catch {
            
        }
    }
    
    @IBAction func cancel() {
        assert(previousDrawerVC != nil)
        pop()
    }
    
    @IBAction func beginEditingFoodInfo() {
        nutritionInfoFields.forEach { $0.isEnabled = true }
        
    }
    
    @IBAction func finishEditingFoodInfo() {
        nutritionInfoFields.forEach { $0.isEnabled = false }
        
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        switch drawer.drawerPosition {
        case .closed:
            fatalError("`drawerPosition` can not be `closed`")
        case .collapsed:
            view.endEditing(false)
        case .open:
            break
        case .partiallyRevealed:
            view.endEditing(false)
        }
    }
    
    deinit {
        _datePicker.removeTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        NotificationCenter.default.removeObserver(self)
    }
}

extension AddOrEditFoodViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        pulleyVC.setDrawerPosition(position: .open, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}

extension Date {
    var roundedToNearestHalfHour: Date {
        return self
    }
}
