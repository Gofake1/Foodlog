//
//  Common+UIKit.swift
//  Foodlog
//
//  Created by David on 3/26/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

extension Array where Element == (String, UIColor) {
    var attributedString: NSAttributedString {
        guard count > 0 else { return NSAttributedString() }
        guard count > 1 else {
            let string = self[0].0, color = self[0].1
            let attrString = NSMutableAttributedString(string: string)
            attrString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: string.count))
            return attrString
        }
        var interleaved = [(String, UIColor)]()
        for el in self[0..<count-1] {
            interleaved.append(el)
            interleaved.append((" · ", UIColor.darkText))
        }
        interleaved.append(self[count-1])
        assert(interleaved.count == count*2-1)
        var string = ""
        var ranges = [NSRange]()
        for (str, _) in interleaved {
            ranges.append(NSRange(location: string.count, length: str.count))
            string += str
        }
        let attrString = NSMutableAttributedString(string: string)
        for (color, range) in zip(interleaved.map({ $0.1 }), ranges) {
            attrString.addAttribute(.foregroundColor, value: color, range: range)
        }
        return attrString
    }
}

class FlowContainerView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: intrinsicHeight)
    }
    private var intrinsicHeight = CGFloat(0.0)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var currentOrigin = CGPoint.zero
        var lineHeight = CGFloat(0.0)
        for subview in subviews {
            let size = subview.bounds.size == .zero ? subview.intrinsicContentSize : subview.bounds.size
            if currentOrigin.x+size.width > bounds.width {
                currentOrigin.x = 0.0
                currentOrigin.y += lineHeight + 10.0
                lineHeight = 0.0
            }
            subview.frame = CGRect(origin: currentOrigin, size: size)
            lineHeight = max(lineHeight, size.height)
            currentOrigin.x += size.width + 6.0
        }
        intrinsicHeight = lineHeight + currentOrigin.y
        invalidateIntrinsicContentSize()
    }
}

@IBDesignable
class PillView: UIView {
    @IBInspectable var fillColor: UIColor?
    
    override func draw(_ rect: CGRect) {
        fillColor?.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: rect.height/2).fill()
    }
}