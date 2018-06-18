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
        case editFood
        case editFoodEntry
        case detail
    }
    
    static let pulleyVC: PulleyViewController = {
        defer { drawerStack.append((addOrSearchVC, .addOrSearch)) }
        let pulleyVC = PulleyViewController(contentViewController: logVC, drawerViewController: addOrSearchVC)
        pulleyVC.drawerBackgroundVisualEffectView = nil
        return pulleyVC
    }()
    private static var drawerStack = [(vc: PulleyDrawerViewController, state: DrawerState)]()
    private static let addOrSearchVC: AddOrSearchViewController = makeVC(.addOrSearch)
    private static let logVC: LogViewController = makeVC(.log)
    private static let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    // MARK: - Add or search drawer
    
    static func clearAddOrSearchFilter() {
        addOrSearchVC.clearFilter()
    }
    
    // MARK: - Add or edit drawer
    
    static func addEntryForExistingFood(_ foodEntry: FoodEntry) {
        assert(drawerStack.last!.state == .addOrSearch)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = AddEntryForExistingFoodContext(foodEntry)
        push(vc, .addFoodEntry)
    }
    
    static func addEntryForNewFood(_ foodEntry: FoodEntry) {
        assert(drawerStack.last!.state == .addOrSearch)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = AddEntryForNewFoodContext(foodEntry)
        push(vc, .addFoodEntry)
    }
    
    static func editFood(_ food: Food) {
        let validStates = Set(arrayLiteral: DrawerState.addOrSearch, .detail)
        assert(validStates.contains(drawerStack.last!.state))
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = EditFoodContext(food)
        push(vc, .editFood)
    }
    
    static func editFoodEntry(_ foodEntry: FoodEntry) {
        assert(drawerStack.last!.state == .detail)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = EditFoodEntryContext(foodEntry)
        push(vc, .editFoodEntry)
    }
    
    static func dismissAddOrEdit() {
        let validStates = Set(arrayLiteral: DrawerState.addFoodEntry, .editFood, .editFoodEntry)
        assert(validStates.contains(drawerStack.last!.state))
        pop()
    }
    
    // MARK: - Detail drawer
    
    static func showDetail(_ presentable: LogDetailPresentable) {
        let logDetailVC: LogDetailViewController = makeVC(.logDetail)
        logDetailVC.detailPresentable = presentable
        switch drawerStack.last!.state {
        case .addOrSearch:      push(logDetailVC, .detail)
        case .addFoodEntry:     fallthrough
        case .editFood:         fallthrough
        case .editFoodEntry:    fallthrough
        case .detail:           popAndPush(logDetailVC, .detail)
        }
    }
    
    static func dismissDetail() {
        assert(drawerStack.last!.state == .detail)
        pop()
    }
    
    // MARK: - Log
    
    // TODO: Filter by date
    
    static func filterLog(_ food: Food) {
        addOrSearchVC.filter(food)
        logVC.filter(food)
    }
    
    static func filterLog(_ tag: Tag) {
        addOrSearchVC.filter(tag)
        logVC.filter(tag)
    }
    
    static func clearLogFilter() {
        logVC.clearFilter()
    }
    
    static func clearLogSelection() {
        logVC.clearTableSelection()
    }
    
    // MARK: - Drawer
    
    private static func push(_ newDrawerVC: PulleyDrawerViewController, _ newDrawerState: DrawerState) {
        drawerStack.append((newDrawerVC, newDrawerState))
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    private static func pop() {
        drawerStack.removeLast()
        pulleyVC.setDrawerContentViewController(controller: drawerStack.last!.vc)
    }
    
    private static func popAndPush(_ newDrawerVC: PulleyDrawerViewController, _ newDrawerState: DrawerState) {
        drawerStack.removeLast()
        drawerStack.append((newDrawerVC, newDrawerState))
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    // MARK: -
    
    static func makeVC<A: UIViewController>(_ kind: Kind) -> A {
        return storyboard.instantiateViewController(withIdentifier: kind.rawValue) as! A
    }
}

// MARK: -

class PulleyDrawerViewController: UIViewController {}

extension PulleyDrawerViewController: PulleyDrawerViewControllerDelegate {
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 64.0 + bottomSafeArea
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 264.0 + bottomSafeArea
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .open, .partiallyRevealed]
    }
}
