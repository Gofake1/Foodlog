//
//  AddFoodViewController.swift
//  Foodlog
//
//  Created by David on 12/30/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

private let _dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .short
    return df
}()

class AddFoodViewController: UIViewController {
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
    
    var addOrSearchVC: AddOrSearchViewController!
    var foodName: String!
    private weak var pulleyVC: PulleyViewController!
    
    override func viewDidLoad() {
        foodNameLabel.text = foodName
        dateField.text = _dateFormatter.string(from: Date())
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        dateField.inputView = datePicker
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        pulleyVC = self.parent as! PulleyViewController
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        dateField.text = _dateFormatter.string(from: sender.date)
    }
    
    @IBAction func addFoodToLog() {
        
    }
    
    @IBAction func cancel() {
        pulleyVC.setDrawerContentViewController(controller: addOrSearchVC)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
