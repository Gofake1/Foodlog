//
//  MyScrollView.swift
//  Foodlog
//
//  Created by David on 3/22/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class MyScrollView: UIScrollView {
    var shouldScroll = false
    
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        if shouldScroll {
            super.setContentOffset(contentOffset, animated: animated)
        }
    }
}
