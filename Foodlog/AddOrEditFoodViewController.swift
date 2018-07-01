//
//  AddFoodViewController.swift
//  Foodlog
//
//  Created by David on 12/30/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

final class AddOrEditFoodViewController: PulleyDrawerViewController {
    @IBOutlet weak var amountController:            AmountController!
    @IBOutlet weak var dateController:              DateController!
    @IBOutlet weak var foodEntryTagController:      TagController!
    @IBOutlet weak var foodTagController:           TagController!
    @IBOutlet weak var scrollController:            ScrollController!
    @IBOutlet weak var servingSizeController:       ServingSizeController!
    @IBOutlet weak var nutritionController:         NutritionController!
    @IBOutlet weak var addToLogButton:              UIButton!
    @IBOutlet weak var foodNameField:               UITextField!
    @IBOutlet weak var foodNameLabel:               UILabel!
    @IBOutlet weak var foodTagsView:                FlowContainerView!
    @IBOutlet weak var placeholderView:             UIView!
    // A
    @IBOutlet weak var aView:                       UIView!
    @IBOutlet weak var aServingSizeField:           UITextField!
    @IBOutlet weak var aDateField:                  UITextField!
    @IBOutlet weak var aAmountField:                UITextField!
    @IBOutlet weak var aTagsView:                   FlowContainerView!
    // B
    @IBOutlet weak var bView:                       UIView!
    @IBOutlet weak var bDateField:                  UITextField!
    @IBOutlet weak var bAmountField:                UITextField!
    @IBOutlet weak var bTagsView:                   FlowContainerView!
    // C
    @IBOutlet weak var cView:                       UIView!
    @IBOutlet weak var cServingSizeField:           UITextField!

    var context: AddOrEditFoodContextType!
    
    override func viewDidLoad() {
        foodTagController.tagsView = foodTagsView
        context.configure(self)
        scrollController.enable()
    }
    
    override func modalDidShow() {
        scrollController.disable()
    }
    
    override func modalDidDismiss() {
        scrollController.enable()
    }
    
    func useLabelForName(_ name: String) {
        foodNameLabel.isHidden = false
        foodNameLabel.text = name
    }
    
    func useFieldForName(_ name: String) {
        foodNameField.isHidden = false
        foodNameField.text = name
    }
    
    func configureAddToLogButton(title: String, isEnabled: Bool) {
        addToLogButton.setTitle(title, for: .normal)
        addToLogButton.isEnabled = isEnabled
    }
    
    func useAView() {
        amountController.field = aAmountField
        dateController.field = aDateField
        foodEntryTagController.tagsView = aTagsView
        servingSizeController.field = aServingSizeField
        placeholderView.embedSubview(aView)
    }
    
    func useBView() {
        amountController.field = bAmountField
        dateController.field = bDateField
        foodEntryTagController.tagsView = bTagsView
        placeholderView.embedSubview(bView)
    }
    
    func useCView() {
        servingSizeController.field = cServingSizeField
        placeholderView.embedSubview(cView)
    }
    
    @IBAction func foodNameChanged(_ sender: UITextField) {
        context.name = sender.text!
    }
    
    @IBAction func addFoodEntryToLog() {
        view.endEditing(false)
        
        if let (count, onConfirm) = context.save(completionHandler: {
            if let error = $0 {
                UIApplication.shared.alert(error: error)
            }
        }) {
            let warning = "Editing this food item will affect \(count) entries. This cannot be undone."
            UIApplication.shared.alert(warning: warning, confirm: { onConfirm(); VCController.dismissAddOrEdit() })
        } else {
            VCController.dismissAddOrEdit()
        }
    }
    
    @IBAction func cancel() {
        VCController.dismissAddOrEdit()
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        switch drawer.drawerPosition {
        case .closed:
            fatalError()
        case .collapsed:
            view.endEditing(false)
        case .open:
            break
        case .partiallyRevealed:
            view.endEditing(false)
        }
    }
}

class ScrollController: NSObject {
    @IBOutlet weak var scrollView: MyScrollView!
    
    private var targetFrame = CGRect.zero
    
    /// - precondition: `frame` must be in `scrollView`'s coordinate space
    func scroll(to frame: CGRect) {
        targetFrame = frame
        scrollToFrame()
    }
    
    fileprivate func enable() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    fileprivate func disable() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWasShown(_ aNotification: NSNotification) {
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        VCController.pulleyVC.setDrawerPosition(position: .open, animated: true)
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        scrollToFrame()
    }
    
    @objc private func keyboardWillBeHidden(_ aNotification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    private func scrollToFrame() {
        // Workaround: View's frame is translated down by Pulley
        let fixedViewFrame = scrollView.superview!.convert(targetFrame, to: nil)
        // Workaround: `UIScrollView` scrolls to incorrect first responder frame
        scrollView.shouldScroll = true
        scrollView.scrollRectToVisible(fixedViewFrame, animated: true)
        scrollView.shouldScroll = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

final class MyScrollView: UIScrollView {
    var shouldScroll = false
    
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        guard shouldScroll else { return }
        super.setContentOffset(contentOffset, animated: animated)
    }
}
