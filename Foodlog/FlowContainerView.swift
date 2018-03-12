//
//  FlowContainerView.swift
//  Foodlog
//
//  Created by David on 2/21/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class FlowContainerView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var currentOrigin = CGPoint.zero
        var lineHeight = CGFloat(0.0)
        for subview in subviews {
            let size = subview.intrinsicContentSize
            if currentOrigin.x+size.width > bounds.width {
                currentOrigin.x = 0.0
                currentOrigin.y += lineHeight + 10.0
                lineHeight = 0.0
            }
            subview.frame = CGRect(origin: currentOrigin, size: size)
            lineHeight = max(lineHeight, size.height)
            currentOrigin.x += size.width + 6.0
        }
    }
}
