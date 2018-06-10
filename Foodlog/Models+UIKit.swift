//
//  Models+UIKit.swift
//  Foodlog
//
//  Created by David on 3/24/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

extension Tag {
    var color: UIColor {
        switch ColorCode(rawValue: colorCodeRaw)! {
        case .gray:         return .lightGray
        case .red:          return .red
        case .orange:       return .orange
        case .yellow:       return .yellow
        case .green:        return .green
        case .blue:         return .blue
        case .purple:       return .purple
        }
    }
    var activeButton: UIButton {
        return UIButton(pillFilled: name, color: color)
    }
    var disabledButton: UIButton {
        return UIButton(pillBordered: name, color: color)
    }
}

extension UIButton {
    convenience init(pillBordered title: String, color: UIColor) {
        self.init(type: .custom)
        setTitle(title, for: .normal)
        setTitleColor(color, for: .normal)
        contentEdgeInsets = .init(top: 4.0, left: 6.0, bottom: 4.0, right: 6.0)
        titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        layer.borderColor = color.cgColor
        layer.borderWidth = 1.5
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
    
    convenience init(pillFilled title: String, color: UIColor) {
        self.init(type: .custom)
        setTitle(title, for: .normal)
        backgroundColor = color
        contentEdgeInsets = .init(top: 4.0, left: 6.0, bottom: 4.0, right: 6.0)
        titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
}
