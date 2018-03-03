//
//  DateController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class DateController: NSObject {
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var field: UITextField!
    
    private static let dp: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        return dp
    }()
    private var foodEntry: FoodEntry!
    private var date: Date {
        get { return foodEntry.date }
        set { foodEntry.date = newValue }
    }
    
    override init() {
        super.init()
        DateController.dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }
    
    func setup(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
        field.inputView = DateController.dp
        field.inputAccessoryView = toolbar
        field.text = date.shortDateShortTimeString
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        field.text = sender.date.shortDateShortTimeString
    }
    
    @IBAction func doneEditing() {
        field.resignFirstResponder()
    }
    
    deinit {
        DateController.dp.removeTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }
}
    
extension DateController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if let newDate = textField.text?.dateFromShortDateShortTime {
            date = newDate
        } else {
            date = Date()
            textField.text = date.shortDateShortTimeString
        }
    }
}
