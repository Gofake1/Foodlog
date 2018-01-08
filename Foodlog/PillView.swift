//
//  PillView.swift
//  Foodlog
//
//  Created by David on 1/7/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

@IBDesignable
class PillView: UIView {
    @IBInspectable var fillColor: UIColor?
    
    override func draw(_ rect: CGRect) {
        fillColor?.setFill()
        let pillPath = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        pillPath.fill()
    }
}
