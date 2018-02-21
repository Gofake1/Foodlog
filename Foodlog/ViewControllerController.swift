//
//  ViewControllerController.swift
//  Foodlog
//
//  Created by David on 1/28/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class VCController {
    enum Kind: String {
        case addOrEditFood  = "AddOrEditFood"
        case logDetail      = "LogDetail"
        case pulley         = "Pulley"
    }
    
    enum DrawerState {
        case addOrSearch
        case addFoodEntry
        case editFoodEntry
        case detailFoodEntry
    }
    
    static var drawers = [PulleyDrawerViewController]()
    static var drawerState = [DrawerState]()
    static var logVC: LogViewController!
    static let pulleyVC: PulleyViewController = makeVC(.pulley)
    private static let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    static func addFoodEntry(_ foodEntry: FoodEntry, isNew: Bool) {
        assert(drawerState.last == .addOrSearch)
        let addFoodVC: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        addFoodVC.foodEntry = foodEntry
        addFoodVC.mode = isNew ? .addEntryForNewFood : .addEntryForExistingFood
        push(addFoodVC, .addFoodEntry)
    }
    
    static func editFoodEntry(_ foodEntry: FoodEntry) {
        assert(drawerState.last == .detailFoodEntry)
        let editFoodVC: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        editFoodVC.foodEntry = foodEntry
        editFoodVC.mode = .editEntry
        push(editFoodVC, .editFoodEntry)
    }
    
    static func selectFoodEntry(_ foodEntry: FoodEntry) {
        let logDetailVC: LogDetailViewController = makeVC(.logDetail)
        logDetailVC.detailPresentable = foodEntry
        switch drawerState.last! {
        case .addOrSearch:
            push(logDetailVC, .detailFoodEntry)
        case .addFoodEntry: fallthrough
        case .editFoodEntry: fallthrough
        case .detailFoodEntry:
            popAndPush(logDetailVC, .detailFoodEntry)
        }
    }
    
    // TODO: Filter by tag or date
    static func filterLog(_ food: Food) {
        logVC.filter(food)
    }
    
    static func clearLogFilter() {
        logVC.clearFilter()
    }
    
    static func clearLogSelection() {
        logVC.clearTableSelection()
    }
    
    static func push(_ newDrawerVC: PulleyDrawerViewController, _ newDrawerState: DrawerState) {
        drawers.append(newDrawerVC)
        drawerState.append(newDrawerState)
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    static func pop() {
        drawers.removeLast()
        drawerState.removeLast()
        pulleyVC.setDrawerContentViewController(controller: drawers.last!)
    }
    
    static func popAndPush(_ newDrawerVC: PulleyDrawerViewController, _ newDrawerState: DrawerState) {
        drawers.removeLast()
        drawerState.removeLast()
        drawers.append(newDrawerVC)
        drawerState.append(newDrawerState)
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    private static func makeVC<A: UIViewController>(_ kind: Kind) -> A {
        return storyboard.instantiateViewController(withIdentifier: kind.rawValue) as! A
    }
}
