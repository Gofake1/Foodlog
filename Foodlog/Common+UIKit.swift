//
//  Common+UIKit.swift
//  Foodlog
//
//  Created by David on 3/26/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class GlobalAlerts {
    fileprivate enum Alert {
        case error(Error)
        case warning(String, onConfirm: () throws -> ())
    }
    
    private static var queue = [Alert]()
    
    static func append(error: Error) {
        DispatchQueue.main.async {
            queue.append(.error(error))
            tryPresentingNext()
        }
    }
    
    static func append(warning: String, onConfirm: @escaping () throws -> ()) {
        DispatchQueue.main.async {
            queue.append(.warning(warning, onConfirm: onConfirm))
            tryPresentingNext()
        }
    }
    
    private static func tryPresentingNext() {
        guard let alert = queue.first else { return }
        let vc = UIApplication.shared.keyWindow!.rootViewController!
        if vc.presentedViewController == nil {
            let alert = UIAlertController(alert: alert) {
                queue = Array(queue.dropFirst())
                tryPresentingNext()
            }
            vc.present(alert, animated: true)
        }
    }
}

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

final class FlowContainerView: UIView {
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
final class PillView: UIView {
    @IBInspectable var fillColor: UIColor?
    
    override func draw(_ rect: CGRect) {
        fillColor?.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: rect.height/2).fill()
    }
}

extension UIAlertController {
    fileprivate convenience init(alert: GlobalAlerts.Alert, onDismissal dismissalHandler: @escaping () -> ()) {
        switch alert {
        case .error(let error):
            self.init(error: error, onDismissal: dismissalHandler)
        case .warning(let warning, let onConfirm):
            self.init(warning: warning, onConfirm: onConfirm, onDismissal: dismissalHandler)
        }
    }
    
    fileprivate convenience init(error: Error, onDismissal dismissalHandler: @escaping () -> () = {}) {
        self.init(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in dismissalHandler() }))
    }
    
    fileprivate convenience init(warning: String, onConfirm confirmationHandler: @escaping () throws -> (),
                                 onDismissal dismissalHandler: @escaping () -> () = {})
    {
        self.init(title: "Warning", message: warning, preferredStyle: .alert)
        addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { _ in
            do {
                try confirmationHandler()
            } catch {
                GlobalAlerts.append(error: error)
            }
            dismissalHandler()
        }))
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in dismissalHandler() }))
    }
}

extension UIView {
    func embedSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([topAnchor.constraint(equalTo: view.topAnchor),
                                     bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                     leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     trailingAnchor.constraint(equalTo: view.trailingAnchor)])
    }
}

extension UIViewController {
    func alert(error: Error) {
        let alert = UIAlertController(error: error)
        present(alert, animated: true)
    }
    
    func alert(warning: String, onConfirm: @escaping () throws -> ()) {
        let alert = UIAlertController(warning: warning, onConfirm: onConfirm)
        present(alert, animated: true)
    }
}
