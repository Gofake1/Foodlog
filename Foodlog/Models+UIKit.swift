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
        return colorCode.color
    }
    var activeButton: UIButton {
        return UIButton(pillFilled: name, color: color)
    }
    var disabledButton: UIButton {
        return UIButton(pillBordered: name, color: color)
    }
}

extension Tag.ColorCode {
    var color: UIColor {
        switch self {
        case .gray:         return .lightGray
        case .red:          return .init(red: 0.86, green: 0.0, blue: 0.0, alpha: 1.0)
        case .orange:       return .init(red: 0.91, green: 0.55, blue: 0.01, alpha: 1.0)
        case .yellow:       return .init(red: 0.88, green: 0.79, blue: 0.0, alpha: 1.0)
        case .green:        return .init(red: 0.0, green: 0.53, blue: 0.02, alpha: 1.0)
        case .blue:         return .init(red: 0.14, green: 0.16, blue: 0.8, alpha: 1.0)
        case .purple:       return .init(red: 0.44, green: 0.0, blue: 0.93, alpha: 1.0)
        }
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
