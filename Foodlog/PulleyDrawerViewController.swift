//
//  PulleyDrawerViewController.swift
//  Foodlog
//
//  Created by David on 1/6/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class PulleyDrawerViewController: UIViewController {
    var previousDrawerVC: PulleyDrawerViewController?
    weak var pulleyVC: PulleyViewController!
    
    override func willMove(toParentViewController parent: UIViewController?) {
        pulleyVC = parent as? PulleyViewController
    }
    
    func push(_ newDrawerVC: PulleyDrawerViewController) {
        newDrawerVC.previousDrawerVC = self
        pulleyVC.setDrawerContentViewController(controller: newDrawerVC)
    }
    
    func pop() {
        guard let previousDrawerVC = previousDrawerVC else { return }
        pulleyVC.setDrawerContentViewController(controller: previousDrawerVC)
    }
}

extension PulleyDrawerViewController: PulleyDrawerViewControllerDelegate {
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 60.0 + bottomSafeArea
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 264.0 + bottomSafeArea
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .open, .partiallyRevealed]
    }
}
