//
//  Contexts.swift
//  Foodlog
//
//  Created by David on 3/21/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import Foundation

protocol AddOrEditContextType: class {
    var name: String { get set }
    func configure(_ vc: AddOrEditFoodViewController)
    /// - postcondition: Writes to data store and HealthKit
    /// - returns: If the save operation requires user confirmation, returns a block that should be called.
    func save() -> (Int, () -> ())?
}

final class AddEntryForExistingFoodContext: AddOrEditContextType {    
    var name: String {
        get { return foodEntry.food!.name }
        set { foodEntry.food!.name = newValue }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
        self.foodEntry.food = Food(value: foodEntry.food!)
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.dateController.setup(DefaultDateControllerContext(foodEntry))
        vc.foodNutritionController.setup(AddEntryForExistingFoodNutritionControllerContext(foodEntry.food!))
        vc.measurementController.setup(AddEntryForExistingFoodMeasurementControllerContext(foodEntry))
        vc.tagController.setup(AddEntryForExistingFoodTagControllerContext(foodEntry))
        vc.foodNameLabel.text = name
    }
    
    func save() -> (Int, () -> ())? {
        _addFoodEntry(foodEntry, SearchSuggestion(value: foodEntry.food!.searchSuggestion!))
        return nil
    }
}

final class AddEntryForNewFoodContext: AddOrEditContextType {
    var name: String {
        get { return foodEntry.food!.name }
        set { foodEntry.food!.name = newValue }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.dateController.setup(DefaultDateControllerContext(foodEntry))
        vc.foodNutritionController.setup(AddEntryForNewFoodNutritionControllerContext(foodEntry.food!))
        vc.measurementController.setup(AddEntryForNewFoodMeasurementControllerContext(foodEntry))
        vc.tagController.setup(DefaultTagControllerContext(foodEntry))
        vc.foodNameLabel.text = name
    }
    
    func save() -> (Int, () -> ())? {
        let searchSuggestion = SearchSuggestion()
        searchSuggestion.kindRaw = SearchSuggestion.Kind.food.rawValue
        _addFoodEntry(foodEntry, searchSuggestion)
        return nil
    }
}

final class EditFoodContext: AddOrEditContextType {
    var name: String {
        get { return food.name }
        set {
            foodInfoChanged.value ||= newValue == food.name
            food.name = newValue
        }
    }
    private let food: Food
    private let foodInfoChanged = Ref(false)
    private let originalFood: Food
    
    init(_ food: Food) {
        self.food = Food(value: food)
        originalFood = food
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.foodNutritionController.setup(DefaultFoodNutritionControllerContext(food, foodInfoChanged))
        vc.measurementController.setup(EditFoodMeasurementControllerContext(food, foodInfoChanged))
        vc.tagController.setup(EditFoodTagControllerContext(food))
        vc.foodEntryInfoView.subviews.forEach { $0.removeFromSuperview() }
        vc.foodNameLabel.isHidden = true
        vc.foodNameField.isHidden = false
        vc.foodNameField.text = name
        vc.addToLogButton.setTitle("Update Log", for: .normal)
    }
    
    func save() -> (Int, () -> ())? {
        let affectedFoodEntries = DataStore.foodEntries.filter("food == %@", originalFood)
        return (affectedFoodEntries.count, { [weak self] in
            DataStore.update(self!.food)
            HealthKitStore.shared.update(AnyCollection(affectedFoodEntries))
        })
    }
}

final class EditFoodEntryContext: AddOrEditContextType {
    var name: String {
        get { return foodEntry.food!.name }
        set {
            foodInfoChanged.value ||= newValue != foodEntry.food!.name
            foodEntry.food!.name = newValue
        }
    }
    private let foodEntry: FoodEntry
    private let foodInfoChanged = Ref(false)
    private let originalDay: Day
    private let originalFood: Food
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = FoodEntry(value: foodEntry)
        self.foodEntry.food = Food(value: foodEntry.food!)
        originalDay = foodEntry.days.first!
        originalFood = foodEntry.food!
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.dateController.setup(DefaultDateControllerContext(foodEntry))
        vc.foodNutritionController.setup(DefaultFoodNutritionControllerContext(foodEntry.food!, foodInfoChanged))
        vc.measurementController.setup(EditFoodEntryMeasurementControllerContext(foodEntry, foodInfoChanged))
        vc.tagController.setup(DefaultTagControllerContext(foodEntry))
        vc.foodNameLabel.isHidden = true
        vc.foodNameField.isHidden = false
        vc.foodNameField.text = name
        vc.addToLogButton.setTitle("Update Log", for: .normal)
    }
    
    func save() -> (Int, () -> ())? {
        func _save(_ context: EditFoodEntryContext) {
            if context.originalDay.startOfDay != context.foodEntry.date.startOfDay {
                let correctDay = Day.get(for: context.foodEntry)
                correctDay.foodEntries.append(context.foodEntry)
                DataStore.update(correctDay)
                let wrongDay = Day(value: context.originalDay)
                let index = wrongDay.foodEntries.index(of: context.foodEntry)!
                wrongDay.foodEntries.remove(at: index)
                DataStore.update(wrongDay)
                _ = Day.deleteIfNoEntries(wrongDay)
            } else {
                DataStore.update(context.foodEntry)
            }
            HealthKitStore.shared.update(AnyCollection([context.foodEntry]))
        }
        
        if foodInfoChanged.value {
            let affectedFoodEntries = DataStore.foodEntries.filter("food == %@", originalFood)
            return (affectedFoodEntries.count, { [weak self] in _save(self!) })
        } else {
            _save(self)
            return nil
        }
    }
}

private func _addFoodEntry(_ foodEntry: FoodEntry, _ searchSuggestion: SearchSuggestion) {
    searchSuggestion.lastUsed = Date()
    searchSuggestion.text = foodEntry.food!.name
    foodEntry.food!.searchSuggestion = searchSuggestion
    let day = Day.get(for: foodEntry)
    day.foodEntries.append(foodEntry)
    DataStore.update(day)
    HealthKitStore.shared.save([foodEntry.hkObject].compactMap { $0 })
}

extension HealthKitStore {
    func update(_ foodEntries: AnyCollection<FoodEntry>) {
        let idsToDelete = foodEntries.map { $0.id }
        let hkObjectsToSave = foodEntries.compactMap { $0.hkObject }
        delete(idsToDelete) { [weak self] in self?.save(hkObjectsToSave) }
    }
}
