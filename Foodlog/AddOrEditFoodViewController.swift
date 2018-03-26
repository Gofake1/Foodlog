//
//  AddFoodViewController.swift
//  Foodlog
//
//  Created by David on 12/30/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

// TODO: UI to change measurement representation
class AddOrEditFoodViewController: PulleyDrawerViewController {    
    @IBOutlet weak var dateController:          DateController!
    @IBOutlet weak var foodNutritionController: FoodNutritionController!
    @IBOutlet weak var measurementController:   MeasurementController!
    @IBOutlet weak var tagController:           TagController!
    @IBOutlet weak var scrollController:        ScrollController!
    @IBOutlet weak var foodNameLabel:           UILabel!
    @IBOutlet weak var foodNameField:           UITextField!
    @IBOutlet weak var addToLogButton:          UIButton!
    @IBOutlet weak var foodEntryInfoView:       UIView!

    var context: AddOrEditContextType!
    
    override func viewDidLoad() {
        context.configure(self)
        scrollController.setup()
    }
    
    @IBAction func foodNameChanged(_ sender: UITextField) {
        context.name = sender.text!
    }
    
    @IBAction func addFoodEntryToLog() {
        view.endEditing(false)
        
        if let (count, onConfirm) = context.save() {
            let warning = "Editing this food item will affect \(count) entries. This cannot be undone."
            UIApplication.shared.alert(warning: warning, confirm: { onConfirm(); VCController.pop() })
        } else {
            VCController.pop()
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
}

class ScrollController: NSObject {
    @IBOutlet weak var scrollView: MyScrollView!
    
    private weak var activeView: UIView?
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    func scrollToView(_ view: UIView?) {
        activeView = view
        scrollToActiveView()
    }
    
    private func scrollToActiveView() {
        guard let view = activeView else { return }
        // Workaround: View's frame is translated down by Pulley
        let fixedViewFrame = scrollView.superview!.convert(view.frame, to: nil)
        // Workaround: `UIScrollView` scrolls to incorrect first responder frame
        scrollView.shouldScroll = true
        scrollView.scrollRectToVisible(fixedViewFrame, animated: true)
        scrollView.shouldScroll = false
    }
    
    @objc func keyboardWasShown(_ aNotification: NSNotification) {
        VCController.pulleyVC.setDrawerPosition(position: .open, animated: true)
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        scrollToActiveView()
    }
    
    @objc func keyboardWillBeHidden(_ aNotification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
