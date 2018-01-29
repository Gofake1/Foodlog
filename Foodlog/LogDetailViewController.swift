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
    
    var detailPresentable: FoodEntry? //LogDetailPresentable?
    fileprivate static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    private var viewBounds = CGRect()
    
    override func viewDidLoad() {
        titleLabel.text = detailPresentable?.logDetailTitle
        subtitleLabel.text = detailPresentable?.logDetailSubtitle
    }
    
    override func viewDidLayoutSubviews() {
        // Workaround: Multiple calls to `viewDidLayoutSubviews` will cause `attributes(_:_:)` to throw exception
        guard viewBounds != view.bounds else { return }
        viewBounds = view.bounds
        
        // Workaround: `textView` constraints don't update width
        textView.bounds.size.width = view.bounds.width - 22
        
        var attributes = textView.attributedText.attributes(at: 0, effectiveRange: nil)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let location = textView.bounds.width - textView.textContainer.lineFragmentPadding * 2
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: location)]
        attributes[.paragraphStyle] = paragraphStyle
        let textViewString = detailPresentable?.logDetailText ?? "Error: No information found for this entry."
        textView.attributedText = NSAttributedString(string: textViewString, attributes: attributes)
        
        textViewHeightConstraint.constant = textView.sizeThatFits(
            CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    @IBAction func edit() {
        guard let foodEntry = detailPresentable else { return }
        VCController.editFoodEntry(foodEntry)
    }
    
    @IBAction func cancel() {
        VCController.pop()
    }
}

//protocol LogDetailPresentable {
//    var logDetailTitle: String { get }
//    var logDetailSubtitle: String { get }
//    var logDetailText: String { get }
//}

extension FoodEntry /*: LogDetailPresentable*/ {
    var logDetailTitle: String {
        return food?.name ?? "Unnamed"
    }
    
    var logDetailSubtitle: String {
        return LogDetailViewController.dateFormatter.string(from: date)
    }
    
    var logDetailText: String {
        func detailString(_ value: Float, _ kind: NutritionKind) -> String {
            guard value != 0.0 else { return "" }
            return "\(kind)\t\(value.pretty!)\(kind.unit.short)\n"
        }
        
        guard let food = food else { return "Error: No information found for this entry's food." }
        var str = ""
        str += detailString(food.calories, .calories)
        str += detailString(food.totalFat, .totalFat)
        str += detailString(food.saturatedFat, .saturatedFat)
        str += detailString(food.monounsaturatedFat, .monounsaturatedFat)
        str += detailString(food.polyunsaturatedFat, .polyunsaturatedFat)
        str += detailString(food.transFat, .transFat)
        str += detailString(food.cholesterol, .cholesterol)
        str += detailString(food.sodium, .sodium)
        str += detailString(food.totalCarbohydrate, .totalCarbohydrate)
        str += detailString(food.dietaryFiber, .dietaryFiber)
        str += detailString(food.sugars, .sugars)
        str += detailString(food.protein, .protein)
        str += detailString(food.vitaminA, .vitaminA)
        str += detailString(food.vitaminB6, .vitaminB6)
        str += detailString(food.vitaminB12, .vitaminB12)
        str += detailString(food.vitaminC, .vitaminC)
        str += detailString(food.vitaminD, .vitaminD)
        str += detailString(food.vitaminE, .vitaminE)
        str += detailString(food.vitaminK, .vitaminK)
        str += detailString(food.calcium, .calcium)
        str += detailString(food.iron, .iron)
        str += detailString(food.magnesium, .magnesium)
        str += detailString(food.potassium, .potassium)
        return str
    }
}
