//
//  DateController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class DateController: NSObject {
    @IBOutlet weak var toolbar: UIToolbar!
    
    var field: UITextField!
    private var context: DateControllerContext!
    private var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.minuteInterval = 30
        return dp
    }()
    
    func setup(_ context: DateControllerContext) {
        self.context = context
        datePicker.date = context.date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        field.delegate = self
        field.inputView = datePicker
        field.inputAccessoryView = toolbar
        field.text = context.date.shortDateShortTimeString
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        field.text = sender.date.shortDateShortTimeString
    }
}
    
extension DateController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        context.date = datePicker.date
    }
}

extension DateController {
    final class ExistingFoodEntry {
        private let foodEntry: FoodEntry
        private let changes: Changes<FoodEntry>
        
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

protocol DateControllerContext {
    var date: Date { get set }
}

extension DateController.ExistingFoodEntry: DateControllerContext {
    var date: Date {
        get { return foodEntry.date }
        set {
            changes.insert(change: \FoodEntry.date)
            foodEntry.date = newValue
        }
    }
}

extension DateController.NewFoodEntry: DateControllerContext {
    var date: Date {
        get { return foodEntry.date }
        set { foodEntry.date = newValue }
    }
}
