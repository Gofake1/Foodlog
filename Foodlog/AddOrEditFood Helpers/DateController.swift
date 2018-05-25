//
//  DateController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class DateController: NSObject {
    @IBOutlet weak var scrollController: ScrollController!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var field: UITextField!
    
    private var context: DateControllerContext!
    private var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.minuteInterval = 30
        return dp
    }()
    
    func setup(_ context: DateControllerContext) {
        self.context = context
        field.inputView = datePicker
        field.inputAccessoryView = toolbar
        field.text = context.date.shortDateShortTimeString
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        field.text = sender.date.shortDateShortTimeString
    }
}
    
extension DateController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollController.scrollToView(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if let newDate = textField.text?.dateFromShortDateShortTime {
            context.date = newDate
        } else {
            context.date = Date()
            textField.text = context.date.shortDateShortTimeString
        }
    }
}

extension DateController {
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

protocol DateControllerContext {
    var date: Date { get set }
}

extension DateController.ExistingFoodEntry: DateControllerContext {
    var date: Date {
        get { return foodEntry.date }
        set {
            foodEntryChanges.insert(change: \FoodEntry.date)
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
