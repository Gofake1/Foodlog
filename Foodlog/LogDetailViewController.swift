//
//  LogDetailViewController.swift
//  Foodlog
//
//  Created by David on 1/6/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class LogDetailViewController: PulleyDrawerViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    var detailPresentable: LogDetailPresentable!
    private static var stringAttributes: [NSAttributedStringKey: Any]!
    
    override func viewDidLoad() {
        titleLabel.text = detailPresentable.logDetailTitle
        subtitleLabel.text = detailPresentable.logDetailSubtitle
        
        if LogDetailViewController.stringAttributes == nil {
            var attributes = textView.attributedText.attributes(at: 0, longestEffectiveRange: nil, in:
                NSRange(location: 0, length: textView.attributedText.length))
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            let location = textView.textContainer.size.width - textView.textContainer.lineFragmentPadding * 2
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: location)]
            attributes[.paragraphStyle] = paragraphStyle
            LogDetailViewController.stringAttributes = attributes
        }
        textView.attributedText = NSAttributedString(string: detailPresentable.logDetailText,
                                                     attributes: LogDetailViewController.stringAttributes)
        
        textViewHeightConstraint.constant = textView.sizeThatFits(
            CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    @IBAction func cancel() {
        assert(previousDrawerVC != nil)
        pop()
    }
}

protocol LogDetailPresentable {
    var logDetailTitle: String { get }
    var logDetailSubtitle: String { get }
    var logDetailText: String { get }
}

extension FoodEntry: LogDetailPresentable {
    var logDetailTitle: String {
        return food?.name ?? "Unnamed"
    }
    
    var logDetailSubtitle: String {
        return "\(date)"
    }
    
    var logDetailText: String {
        guard let food = food else { return "Error: No information found for this entry's food." }
        var str = ""
        str += food.calories == 0           ? "" : "Calories\t\(food.calories)\n"
        str += food.totalFat == 0           ? "" : "Total Fat\t\(food.totalFat)\n"
        str += food.saturatedFat == 0       ? "" : "Saturated Fat\t\(food.saturatedFat)\n"
        str += food.monounsaturatedFat == 0 ? "" : "Monounsaturated Fat\t\(food.monounsaturatedFat)\n"
        str += food.polyunsaturatedFat == 0 ? "" : "Polyunsaturated Fat\t\(food.polyunsaturatedFat)\n"
        str += food.transFat == 0           ? "" : "Trans Fat\t\(food.transFat)\n"
        str += food.cholesterol == 0        ? "" : "Cholesterol\t\(food.cholesterol)\n"
        str += food.sodium == 0             ? "" : "Sodium\t\(food.sodium)\n"
        str += food.totalCarbohydrate == 0  ? "" : "Total Carbohydrate\t\(food.totalCarbohydrate)\n"
        str += food.dietaryFiber == 0       ? "" : "Dietary Fiber\t\(food.dietaryFiber)\n"
        str += food.sugars == 0             ? "" : "Sugars\t\(food.sugars)\n"
        str += food.protein == 0            ? "" : "Protein\t\(food.protein)\n"
        str += food.vitaminA == 0           ? "" : "Vitamin A\t\(food.vitaminA)\n"
        str += food.vitaminB6 == 0          ? "" : "Vitamin B6\t\(food.vitaminB6)\n"
        str += food.vitaminB12 == 0         ? "" : "Vitamin B12\t\(food.vitaminB12)\n"
        str += food.vitaminC == 0           ? "" : "Vitamin C\t\(food.vitaminC)\n"
        str += food.vitaminD == 0           ? "" : "Vitamin D\t\(food.vitaminD)\n"
        str += food.vitaminE == 0           ? "" : "Vitamin E\t\(food.vitaminE)\n"
        str += food.vitaminK == 0           ? "" : "Vitamin K\t\(food.vitaminK)\n"
        str += food.calcium == 0            ? "" : "Calcium\t\(food.calcium)\n"
        str += food.iron == 0               ? "" : "Iron\t\(food.iron)\n"
        return str
    }
}
