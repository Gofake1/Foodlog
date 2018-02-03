//
//  DateController.swift
//  Foodlog
//
//  Created by David on 1/15/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class DateController: NSObject {
    @IBOutlet weak var addOrEditVC: AddOrEditFoodViewController!
    @IBOutlet weak var field: UITextField!
    
    private static let dp: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        return dp
    }()
    private var date: Date {
        get { return addOrEditVC.foodEntry.date }
        set { addOrEditVC.foodEntry.date = newValue }
    }
    
    override init() {
        super.init()
        DateController.dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }
    
    func setup() {
        field.inputView = DateController.dp
        field.text = date.shortDateShortTimeString
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        field.text = sender.date.shortDateShortTimeString
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
