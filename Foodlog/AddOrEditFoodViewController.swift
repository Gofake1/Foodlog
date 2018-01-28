//
//  AddFoodViewController.swift
//  Foodlog
//
//  Created by David on 12/30/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

class MyScrollView: UIScrollView {
    var shouldScroll = false

    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        if shouldScroll {
            super.setContentOffset(contentOffset, animated: animated)
        }
    }
}

class AddOrEditFoodViewController: PulleyDrawerViewController {
    enum Mode {
        case addExistingFood
        case addNewFood
        case editExistingFood
    }
    
    @IBOutlet weak var dateController:          DateController!
    @IBOutlet weak var measurementController:   MeasurementController!
    @IBOutlet weak var foodNutritionController: FoodNutritionController!
    @IBOutlet weak var scrollView:              MyScrollView!
    @IBOutlet weak var foodNameLabel:           UILabel!
    @IBOutlet weak var foodNameField:           UITextField!
    @IBOutlet weak var addToLogButton:          UIButton!

    weak var activeNutritionField: UITextField? {
        didSet {
            scrollToActiveField()
        }
    }
    var userChangedFoodInfo = false
    var foodEntry: FoodEntry!
    var mode: Mode!
    
    override func viewDidLoad() {
        switch mode! {
        case .addExistingFood: fallthrough
        case .addNewFood:
            foodNameLabel.text = foodEntry.food?.name
        case .editExistingFood:
            // Make unmanaged versions of model objects
            foodEntry = FoodEntry(value: foodEntry)
            foodEntry.food = Food(value: foodEntry.food!)
            
            foodNameLabel.isHidden = true
            foodNameField.isHidden = false
            foodNameField.text = foodEntry.food?.name
            addToLogButton.setTitle("Update Log", for: .normal)
        }
        
        dateController.setup()
        measurementController.setup()
        foodNutritionController.setup(mode)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    private func scrollToActiveField() {
        guard let textField = activeNutritionField else { return }
        // Workaround: Text field frame is translated down by Pulley
        let fixedTextFieldFrame = view.superview!.convert(textField.frame, to: nil)
        // Workaround: `UIScrollView` scrolls to incorrect first responder frame
        scrollView.shouldScroll = true
        scrollView.scrollRectToVisible(fixedTextFieldFrame, animated: true)
        scrollView.shouldScroll = false
    }
    
    @objc func keyboardWasShown(_ aNotifcation: NSNotification) {
        pulleyVC.setDrawerPosition(position: .open, animated: true)
        
        guard let userInfo = aNotifcation.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        scrollToActiveField()
    }
    
    @objc func keyboardWillBeHidden(_ aNotification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @IBAction func foodNameChanged(_ sender: UITextField) {
        guard let newName = sender.text else { return }
        foodEntry.food?.name = newName
        userChangedFoodInfo = true
    }
    
    /// - postcondition: Writes to Realm
    @IBAction func addFoodEntryToLog() {
        func addAndPop(_ foodEntry: FoodEntry, update: Bool) {
            if update {
                DataStore.update(foodEntry)
            } else {
                DataStore.add(foodEntry)
            }
            pop()
        }
        
        view.endEditing(false)
        
        switch mode! {
        case .addNewFood:
            addAndPop(foodEntry, update: false)
        case .addExistingFood:
            addAndPop(foodEntry, update: false)
        case .editExistingFood:
            if userChangedFoodInfo {
                func warningString(_ count: Int) -> String {
                    return "Editing this food item will affect \(count) entries. This cannot be undone."
                }
                
                UIApplication.shared.alert(warning: warningString(0/* TODO: Get count of `FoodEntry`'s with this Food*/)) { [weak self] in
                    guard let foodEntry = self?.foodEntry else { return }
                    // TODO: Update all affected `FoodEntry`'s `healthKitStatus`
                    addAndPop(foodEntry, update: true)
                }
            } else {
                addAndPop(foodEntry, update: true)
            }
        }
    }
    
    @IBAction func cancel() {
        assert(previousDrawerVC != nil)
        pop()
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
        NotificationCenter.default.removeObserver(self)
    }
}
