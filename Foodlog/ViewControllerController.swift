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
        return PulleyViewController(contentViewController: logVC, drawerViewController: addOrSearchVC)
    }()
    private(set) static var drawerStack = [(vc: PulleyDrawerViewController, state: DrawerState)]()
    private static let addOrSearchVC: AddOrSearchViewController = makeVC(.addOrSearch)
    private static let logVC: LogViewController = makeVC(.log)
    private static let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    static func addEntryForExistingFood(_ foodEntry: FoodEntry) {
        assert(drawerStack.last?.state == .addOrSearch)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = AddEntryForExistingFoodContext(foodEntry)
        push(vc, .addFoodEntry)
    }
    
    static func addEntryForNewFood(_ foodEntry: FoodEntry) {
        assert(drawerStack.last?.state == .addOrSearch)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = AddEntryForNewFoodContext(foodEntry)
        push(vc, .addFoodEntry)
    }
    
    static func editFood(_ food: Food) {
        assert(drawerStack.last?.state == .detail)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = EditFoodContext(food)
        push(vc, .editFood)
    }
    
    static func editFoodEntry(_ foodEntry: FoodEntry) {
        assert(drawerStack.last?.state == .detail)
        let vc: AddOrEditFoodViewController = makeVC(.addOrEditFood)
        vc.context = EditFoodEntryContext(foodEntry)
        push(vc, .editFoodEntry)
    }
    
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
    
    // TODO: Filter by date
    
    static func filterLog(_ food: Food) {
        logVC.filter(food)
    }
    
    static func filterLog(_ tag: Tag) {
        logVC.filter(tag)
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
