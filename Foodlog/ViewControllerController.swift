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
        case addOrSearch    = "AddOrSearch"
        case log            = "Log"
        case logDetail      = "LogDetail"
        case tag            = "Tag"
    }
    
    enum DrawerState {
        case addOrSearch
        case addFoodEntry
        case editFoodEntry
        case detailFoodEntry
    }
    
    static var drawerStack = [(vc: PulleyDrawerViewController, state: DrawerState)]()
    static let addOrSearchVC: AddOrSearchViewController = makeVC(.addOrSearch)
    static let logVC: LogViewController = makeVC(.log)
    static let pulleyVC: PulleyViewController = {
        defer {
            drawerStack.append((addOrSearchVC, .addOrSearch))
        }
        return PulleyViewController(contentViewController: logVC, drawerViewController: addOrSearchVC)
    }()
    private static let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    static func addFoodEntry(_ foodEntry: FoodEntry, isNew: Bool) {
        assert(drawerStack.last?.state == .addOrSearch)
        let addFoodVC: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        addFoodVC.foodEntry = foodEntry
        addFoodVC.mode = isNew ? .addEntryForNewFood : .addEntryForExistingFood
        push(addFoodVC, .addFoodEntry)
    }
    
    static func editFoodEntry(_ foodEntry: FoodEntry) {
        assert(drawerStack.last?.state == .detailFoodEntry)
        let editFoodVC: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        editFoodVC.foodEntry = foodEntry
        editFoodVC.mode = .editEntry
        push(editFoodVC, .editFoodEntry)
    }
    
    static func selectFoodEntry(_ foodEntry: FoodEntry) {
        let logDetailVC: LogDetailViewController = makeVC(.logDetail)
        logDetailVC.detailPresentable = foodEntry
        switch drawerStack.last!.state {
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
    
    private static func push(_ newDrawerVC: PulleyDrawerViewController, _ newDrawerState: DrawerState) {
        drawerStack.append((newDrawerVC, newDrawerState))
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    static func pop() {
        drawerStack.removeLast()
        pulleyVC.setDrawerContentViewController(controller: drawerStack.last!.vc)
    }
    
    private static func popAndPush(_ newDrawerVC: PulleyDrawerViewController, _ newDrawerState: DrawerState) {
        drawerStack.removeLast()
        drawerStack.append((newDrawerVC, newDrawerState))
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    static func makeVC<A: UIViewController>(_ kind: Kind) -> A {
        return storyboard.instantiateViewController(withIdentifier: kind.rawValue) as! A
    }
}
