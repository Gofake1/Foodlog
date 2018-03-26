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
    
    private static let dp: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        return dp
    }()
    private var context: DateControllerContext!
    
    func setup(_ context: DateControllerContext) {
        self.context = context
        DateController.dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        field.inputView = DateController.dp
        field.inputAccessoryView = toolbar
        field.text = context.date.shortDateShortTimeString
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

protocol DateControllerContext {
    var date: Date { get set }
}

final class DefaultDateControllerContext: DateControllerContext {
    var date: Date {
        get { return foodEntry.date }
        set { foodEntry.date = newValue }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
}
