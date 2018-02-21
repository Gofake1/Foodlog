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
        case addEntryForExistingFood
        case addEntryForNewFood
        case editEntry
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
    var userChangedFoodInfo = false {
        didSet {
            assert(mode == .editEntry)
        }
    }
    var foodEntry: FoodEntry!
    var mode: Mode!
    private var originalFood: Food?
    
    override func viewDidLoad() {
        switch mode! {
        case .addEntryForExistingFood:
            // Make unmanaged versions of model objects
            foodEntry.food = Food(value: foodEntry.food!)
            
            foodNameLabel.text = foodEntry.food?.name
        case .addEntryForNewFood:
            foodNameLabel.text = foodEntry.food?.name
        case .editEntry:
            // Use original `Food` to filter `FoodEntry`s
            originalFood = foodEntry.food
            
            foodEntry = FoodEntry(value: foodEntry)
            foodEntry.food = Food(value: foodEntry.food!)
            
            foodNameLabel.isHidden = true
            foodNameField.isHidden = false
            foodNameField.text = foodEntry.food?.name
            addToLogButton.setTitle("Update Log", for: .normal)
        }
        
        dateController.setup()
        measurementController.setup(mode)
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
        VCController.pulleyVC.setDrawerPosition(position: .open, animated: true)
        
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
    
    // TODO: Make Realm and HealthKit transactions atomic
    /// - postcondition: Writes to Realm and HealthKit
    @IBAction func addFoodEntryToLog() {
        func addFoodEntry(_ searchSuggestion: SearchSuggestion) {
            searchSuggestion.kind = SearchSuggestion.Kind.food.rawValue
            searchSuggestion.lastUsed = Date()
            searchSuggestion.text = foodEntry.food!.name
            foodEntry.food?.searchSuggestion = searchSuggestion
            let day: Day
            if let existingDay = DataStore.object(Day.self, primaryKey: foodEntry.date.startOfDay.hashValue) {
                day = Day(value: existingDay)
            } else {
                day = Day(foodEntry.date.startOfDay)
            }
            day.foodEntries.append(foodEntry)
            DataStore.update(day)
            HealthKitStore.shared.save([foodEntry.hkObject].compactMap { $0 }, {})
            VCController.pop()
        }
        
        view.endEditing(false)
        
        switch mode! {
        case .addEntryForNewFood:
            addFoodEntry(SearchSuggestion())
        case .addEntryForExistingFood:
            addFoodEntry(SearchSuggestion(value: foodEntry.food!.searchSuggestion!))
        case .editEntry:
            if userChangedFoodInfo {
                func warningString(_ count: Int) -> String {
                    return "Editing this food item will affect \(count) entries. This cannot be undone."
                }
                
                let affectedFoodEntries = Array(DataStore.foodEntries.filter("food == %@", originalFood!))
                UIApplication.shared.alert(warning: warningString(affectedFoodEntries.count)) { [weak self] in
                    guard let foodEntry = self?.foodEntry else { return }
                    DataStore.update(foodEntry)
                    HealthKitStore.shared.update(affectedFoodEntries)
                    VCController.pop()
                }
            } else {
                DataStore.update(foodEntry)
                HealthKitStore.shared.update([foodEntry!])
                VCController.pop()
            }
        }
    }
    
    @IBAction func cancel() {
        VCController.pop()
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

extension Date {
    var startOfDay: Date {
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: dc) ?? self
    }
}

extension Array where Element == FoodEntry {
    func changeHealthKitStatus(from matching: [FoodEntry.HealthKitStatus], to new: FoodEntry.HealthKitStatus) {
        for entry in self {
            if matching.contains(where: { $0 == entry.healthKitStatus }) {
                let unmanagedEntry = FoodEntry(value: entry)
                unmanagedEntry.healthKitStatusRaw = new.rawValue
                DataStore.update(unmanagedEntry)
            }
        }
    }
}

extension HealthKitStore {
    func update(_ affectedFoodEntries: [FoodEntry]) {
        affectedFoodEntries.changeHealthKitStatus(from: [.writtenAndUpToDate], to: .writtenAndNeedsUpdate)
        let idsToDelete = affectedFoodEntries.map { $0.id }
        let hkObjectsToSave = affectedFoodEntries.compactMap { $0.hkObject }
        delete(idsToDelete) { [weak self] in
            self?.save(hkObjectsToSave) {
                DispatchQueue.main.async {
                    affectedFoodEntries.changeHealthKitStatus(from: [.writtenAndNeedsUpdate, .unwritten],
                                                              to: .writtenAndUpToDate)
                }
            }
        }
    }
}
