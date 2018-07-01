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
        case addOrEditTag   = "AddOrEditTag"
        case addOrSearch    = "AddOrSearch"
        case log            = "Log"
        case logDetail      = "LogDetail"
        case tags           = "Tags"
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
    
    static func presentUnitPicker(_ vc: UIAlertController) {
        present(vc)
    }
    
    // MARK: - Tags
    
    static func addTag(parent tagsVC: TagsViewController) {
        let validStates = Set(arrayLiteral: DrawerState.addFoodEntry, .editFood, .editFoodEntry)
        assert(validStates.contains(drawerStack.last!.state))
        let vc: AddOrEditTagViewController = makeVC(.addOrEditTag)
        vc.context = AddTagContext()
        tagsVC.addChildViewController(vc)
        vc.didMove(toParentViewController: tagsVC)
        tagsVC.showAddTag(view: vc.view)
        vc.nameField.becomeFirstResponder()
    }
    
    static func dismissAddTag(_ vc: AddOrEditTagViewController, newTag: Tag?) {
        (vc.parent! as! TagsViewController).dismissAddTag(view: vc.view, newTag: newTag)
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
    }
    
    static func editTag(_ tag: Tag) {
        assert(drawerStack.last!.state == .addOrSearch)
        let vc: AddOrEditTagViewController = makeVC(.addOrEditTag)
        vc.context = EditTagContext(tag)
        present(ModalContainerViewController(containing: vc))
        drawerStack.last!.vc.modalDidShow()
    }
    
    static func dismissEditTag(_ vc: AddOrEditTagViewController) {
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
        dismiss()
        drawerStack.last!.vc.modalDidDismiss()
    }
    
    static func showTags(context: TagControllerContext, transitioning: UIViewControllerTransitioningDelegate) {
        let validStates = Set(arrayLiteral: DrawerState.addFoodEntry, .editFood, .editFoodEntry)
        assert(validStates.contains(drawerStack.last!.state))
        let vc: TagsViewController = makeVC(.tags)
        vc.context = context
        vc.modalPresentationStyle = .overCurrentContext
        vc.transitioningDelegate = transitioning
        present(vc)
        drawerStack.last!.vc.modalDidShow()
    }
    
    static func dismissTags() {
        dismiss()
        drawerStack.last!.vc.modalDidDismiss()
    }
    
    // MARK: - Detail drawer
    
    static func showDetail(_ presentable: LogDetailPresentable) {
        let logDetailVC: LogDetailViewController = makeVC(.logDetail)
        logDetailVC.detailPresentable = presentable
        switch drawerStack.last!.state {
        case .addOrSearch:
            push(logDetailVC, .detail)
        case .addFoodEntry:     fallthrough
        case .editFood:         fallthrough
        case .editFoodEntry:    fallthrough
        case .detail:
            popAndPush(logDetailVC, .detail)
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
    
    // MARK: - Segues
    
    private static func present(_ vc: UIViewController) {
        pulleyVC.present(vc, animated: true)
    }
    
    private static func dismiss() {
        pulleyVC.dismiss(animated: true)
    }
    
    private static func push(_ vc: PulleyDrawerViewController, _ state: DrawerState) {
        drawerStack.append((vc, state))
        pulleyVC.setDrawerContentViewController(controller: vc)
    }
    
    private static func pop() {
        drawerStack.removeLast()
        pulleyVC.setDrawerContentViewController(controller: drawerStack.last!.vc)
    }
    
    private static func popAndPush(_ vc: PulleyDrawerViewController, _ state: DrawerState) {
        drawerStack.removeLast()
        drawerStack.append((vc, state))
        pulleyVC.setDrawerContentViewController(controller: vc)
    }
    
    // MARK: -
    
    private static func makeVC<A: UIViewController>(_ kind: Kind) -> A {
        return storyboard.instantiateViewController(withIdentifier: kind.rawValue) as! A
    }
}

// MARK: -

/// Presents a custom view controller modally
class ModalContainerViewController: UIViewController {
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var bottomConstraint: NSLayoutConstraint!
    
    init(containing vc: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        view.addSubview(containerView)
        bottomConstraint = view.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor)
        let centerYConstraint = view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        centerYConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: -8.0),
            view.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 8.0),
            centerYConstraint,
            bottomConstraint
            ])
        
        vc.view.layer.cornerRadius = 16.0
        vc.view.layer.shadowOffset = .init(width: 0.0, height: 4.0)
        vc.view.layer.shadowOpacity = 0.2
        vc.view.layer.shadowRadius = 10.0
        addChildViewController(vc)
        vc.didMove(toParentViewController: self)
        containerView.embedSubview(vc.view)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc private func keyboardWasShown(_ aNotification: NSNotification) {
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        bottomConstraint.constant = 16.0 + keyboardFrame.height
        UIView.animate(withDuration: 0.3, animations: { [view] in view!.layoutIfNeeded() })
    }
    
    @objc private func keyboardWillBeHidden(_ aNotification: NSNotification) {
        bottomConstraint.constant = 0.0
        UIView.animate(withDuration: 0.3, animations: { [view] in view!.layoutIfNeeded() })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class PulleyDrawerViewController: UIViewController {
    func modalDidShow() {}
    
    func modalDidDismiss() {}
}

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
