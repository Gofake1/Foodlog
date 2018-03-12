//
//  LogDetailViewController.swift
//  Foodlog
//
//  Created by David on 1/6/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

// TODO: UI for `Food`
class LogDetailViewController: PulleyDrawerViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    var detailPresentable: LogDetailPresentable!
    private var detailTextAttributes: [NSAttributedStringKey: Any]!
    private var valueRepresentation = NutritionKind.ValueRepresentation.real
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = detailPresentable.logDetailTitle
        subtitleLabel.text = detailPresentable.logDetailSubtitle
        
        detailTextAttributes = textView.attributedText.attributes(at: 0, effectiveRange: nil)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let location = textView.bounds.width - textView.textContainer.lineFragmentPadding * 2
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: location)]
        detailTextAttributes[.paragraphStyle] = paragraphStyle
        
        resetLogDetailText()
        
        textViewHeightConstraint.constant = textView.sizeThatFits(
            CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    @IBAction func edit() {
        detailPresentable.editDetailPresentable()
    }
    
    @IBAction func cancel() {
        VCController.clearLogSelection()
        VCController.pop()
    }
    
    @IBAction func toggleValueRepresentation(_ sender: UITapGestureRecognizer) {
        switch valueRepresentation {
        case .percentage:   valueRepresentation = .real
        case .real:         valueRepresentation = .percentage
        }
        resetLogDetailText()
    }
    
    private func resetLogDetailText() {
        let textViewString = detailPresentable.makeDetailText(valueRepresentation)
        textView.attributedText = NSAttributedString(string: textViewString, attributes: detailTextAttributes)
    }
}

protocol LogDetailPresentable {
    var logDetailTitle: String { get }
    var logDetailSubtitle: String { get }
    func editDetailPresentable()
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String
}

extension FoodEntry: LogDetailPresentable {
    var logDetailTitle: String {
        guard let food = food, let measurementString = measurementString else { return "Error: Log Detail Title" }
        return "\(measurementString)\(food.measurementRepresentation.longSuffix) \(food.name)"
    }
    
    var logDetailSubtitle: String {
        return date.mediumDateShortTimeString
    }
    
    func editDetailPresentable() {
        VCController.editFoodEntry(self)
    }
    
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String {
        func detailString(_ real: Float, _ kind: NutritionKind) -> String {
            guard real != 0.0 else { return "" }
            let totalValue = real * measurementFloat
            switch representation {
            case .percentage:
                if let percentage = totalValue.dailyValuePercentageFromReal(kind)?.pretty {
                    return "\(kind)\t\(percentage)%\n"
                } else {
                    return "\(kind)\t\(totalValue.pretty!)\(kind.unit.suffix)\n"
                }
            case .real:
                return "\(kind)\t\(totalValue.pretty!)\(kind.unit.suffix)\n"
            }
        }
        
        guard let food = food else { return "Error: Food Information\n" }
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
        if str == "" {
            str = "No Information\n"
        }
        return str
    }
}

extension Food.MeasurementRepresentation {
    var longSuffix: String {
        switch self {
        case .serving:      return "×"
        case .milligram:    return " mg"
        case .gram:         return " g"
        case .ounce:        return " oz."
        case .pound:        return " lb."
        case .fluidOunce:   return " oz."
        }
    }
}
