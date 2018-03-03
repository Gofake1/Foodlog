//
//  TagController.swift
//  Foodlog
//
//  Created by David on 2/23/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

// TODO: `FlowContainerView.intrinsicContentSize`
class TagController: NSObject {
    @IBOutlet weak var addOrEditVC: AddOrEditFoodViewController!
    @IBOutlet weak var entryTagsView: FlowContainerView!
    @IBOutlet weak var foodTagsView: FlowContainerView!
    
    private static let shadowDuration = 0.4
    private static let shadowRelativeDuration = shadowDuration / animationDuration
    private static let translationDuration = 0.4
    private static let translationRelativeDuration = translationDuration / animationDuration
    private static let animationDuration = shadowDuration + translationDuration
    private weak var animatedTagsView: FlowContainerView!
    
    func setup(_ mode: AddOrEditFoodViewController.Mode) {
        func fill(view: UIView, with tags: [Tag], empty: () -> UIView, make: (Tag) -> UIView) {
            if tags.count == 0 {
                view.addSubview(empty())
            } else {
                for tag in tags {
                    view.addSubview(make(tag))
                }
            }
        }
        
        fill(view: entryTagsView, with: Array(addOrEditVC.foodEntry.tags), empty: {
            let button = UIButton(pill: "add tags", color: .lightGray)
            button.addTarget(self, action: #selector(TagController.foodEntryTagPressed), for: .touchUpInside)
            return button
        }, make: {
            let button = $0.plainButton
            button.addTarget(self, action: #selector(TagController.foodEntryTagPressed), for: .touchUpInside)
            return button
        })
        
        let empty: () -> UIView, make: (Tag) -> UIView
        switch mode {
        case .addEntryForExistingFood:
            empty = {
                let label = UILabel()
                label.textColor = .lightGray
                label.text = "no tags"
                return label
            }
            make = {
                let button = $0.plainButton
                button.isEnabled = false
                return button
            }
        case .addEntryForNewFood: fallthrough
        case .editEntry:
            empty = {
                let button = UIButton(pill: "add tags", color: .lightGray)
                button.addTarget(self, action: #selector(TagController.foodTagPressed), for: .touchUpInside)
                return button
            }
            make = {
                let button = $0.plainButton
                button.addTarget(self, action: #selector(TagController.foodTagPressed), for: .touchUpInside)
                return button
            }
        }
        fill(view: foodTagsView, with: Array(addOrEditVC.foodEntry.food!.tags), empty: empty, make: make)
    }
    
    @objc func foodEntryTagPressed() {
        showModal(tagView: entryTagsView)
    }
    
    @objc func foodTagPressed() {
        showModal(tagView: foodTagsView)
    }
    
    private func showModal(tagView: FlowContainerView) {
        animatedTagsView = tagView
        let tagVC: TagViewController = VCController.makeVC(.tag)
        tagVC.delegate = self
        tagVC.modalPresentationStyle = .overCurrentContext
        tagVC.transitioningDelegate = self
        addOrEditVC.present(tagVC, animated: true, completion: nil)
    }
}

extension TagController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TagController.animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        func makeAnimatedView() -> UIView {
            let view = UIView()
            view.backgroundColor = .white
            view.layer.cornerRadius = 16.0
            view.layer.masksToBounds = false
            view.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
            view.layer.shadowOpacity = 0.2
            view.layer.shadowRadius = 16.0
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
        
        func makeConstraints(view: UIView, left: CGFloat, right: CGFloat, height: CGFloat, centerY: CGFloat) ->
            (left: NSLayoutConstraint, right: NSLayoutConstraint, height: NSLayoutConstraint,
            centerY: NSLayoutConstraint)
        {
            return (NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal,
                                       toItem: transitionContext.containerView, attribute: .left,
                                       multiplier: 1.0, constant: left),
                    NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal,
                                       toItem: transitionContext.containerView, attribute: .right,
                                       multiplier: 1.0, constant: right),
                    NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal,
                                       toItem: nil, attribute: .notAnAttribute,
                                       multiplier: 1.0, constant: height),
                    NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal,
                                       toItem: transitionContext.containerView, attribute: .centerY,
                                       multiplier: 1.0, constant: centerY))
        }
        
        if let toVC = transitionContext.viewController(forKey: .to) as? TagViewController {
            let animatedView = makeAnimatedView()
            animatedView.alpha = 0.0
            transitionContext.containerView.addSubview(animatedView)
            
            let startFrame = animatedTagsView.convert(animatedTagsView.bounds, to: nil)
            let (leftConstraint, rightConstraint, heightConstraint, centerConstraint) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: startFrame.height,
                                centerY: startFrame.midY - toVC.view.frame.height/2)
            NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint, centerConstraint])
            transitionContext.containerView.layoutIfNeeded()
            
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.shadowRelativeDuration,
                                   animations: { animatedView.alpha = 1.0 })
                UIView.addKeyframe(withRelativeStartTime: TagController.shadowRelativeDuration,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    heightConstraint.constant = 214.0
                    centerConstraint.constant = -23.0
                    transitionContext.containerView.layoutIfNeeded()
                }
            }) { _ in
                transitionContext.containerView.addSubview(toVC.view)
                transitionContext.completeTransition(true)
            }
            
        } else if let fromVC = transitionContext.viewController(forKey: .from) as? TagViewController {
            transitionContext.containerView.subviews.forEach { $0.removeFromSuperview() }
            
            let animatedView = makeAnimatedView()
            transitionContext.containerView.addSubview(animatedView)
            
            let (leftConstraint, rightConstraint, heightConstraint, centerConstraint) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: 214.0, centerY: -23.0)
            NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint, centerConstraint])
            transitionContext.containerView.layoutIfNeeded()
            
            let endFrame = animatedTagsView.convert(animatedTagsView.bounds, to: nil)
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    heightConstraint.constant = endFrame.height
                    centerConstraint.constant = endFrame.midY - fromVC.view.frame.height/2
                    transitionContext.containerView.layoutIfNeeded()
                }
                UIView.addKeyframe(withRelativeStartTime: TagController.translationRelativeDuration,
                                   relativeDuration: TagController.shadowRelativeDuration,
                                   animations: { animatedView.alpha = 0.0 })
            }) { _ in
                transitionContext.completeTransition(true)
            }
        }
    }
}

extension TagController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

// TODO: Make filled close button
// TODO: Show confirm button if user (de)selected tags
class TagViewController: UIViewController {
    @IBOutlet weak var tagsView: FlowContainerView!
    
    weak var delegate: TagViewControllerDelegate!
    
    override func viewDidLoad() {
        for tag in DataStore.tags {
            if delegate.tags.contains(tag) {
                tagsView.addSubview(tag.controlButton(true))
            } else {
                tagsView.addSubview(tag.controlButton(false))
            }
        }
        let button = UIButton(pill: "add new tag", color: .lightGray)
        button.addTarget(self, action: #selector(TagViewController.addNewTag), for: .touchUpInside)
        tagsView.addSubview(button)
    }
    
    @objc func addNewTag() {
        
    }
    
    @IBAction func dismiss() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

protocol TagViewControllerDelegate: AnyObject {
    var tags: Set<Tag> { get }
    func addTag(forFoodEntry foodEntry: FoodEntry)
    func removeTag(forFoodEntry foodEntry: FoodEntry)
    func addTag(forFood food: Food)
    func removeTag(forFood food: Food)
}

extension TagController: TagViewControllerDelegate {
    var tags: Set<Tag> {
        return Set(addOrEditVC.foodEntry.tags)
    }
    
    func addTag(forFoodEntry foodEntry: FoodEntry) {
        
    }
    
    func removeTag(forFoodEntry foodEntry: FoodEntry) {
        
    }
    
    func addTag(forFood food: Food) {
        
    }
    
    func removeTag(forFood food: Food) {
        
    }
}

extension Tag {
    var plainButton: UIButton {
        return UIButton(pill: name, color: color)
    }
    var color: UIColor {
        switch ColorCode(rawValue: colorCodeRaw)! {
        case .lightGray:    return .lightGray
        case .red:          return .red
        case .orange:       return .orange
        case .yellow:       return .yellow
        case .green:        return .green
        case .blue:         return .blue
        case .purple:       return .purple
        }
    }
    
    func controlButton(_ isMember: Bool) -> UIButton {
        return isMember ? UIButton(pill: name, color: color, decorator: "×") :
            UIButton(pill: name, color: color, decorator: "+")
    }
}

extension UIButton {
    convenience init(pill title: String, color: UIColor) {
        self.init(type: .custom)
        setTitle(title, for: .normal)
        backgroundColor = color
        contentEdgeInsets = .init(top: 4.0, left: 6.0, bottom: 4.0, right: 6.0)
        titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
    
    convenience init(pill title: String, color: UIColor, decorator: String) {
        self.init(pill: title, color: color)
        bounds.size.width += 10.0
        titleLabel?.bounds.origin.x += 10.0
        let decoratorLabel = UILabel()
        decoratorLabel.text = decorator
        decoratorLabel.frame = CGRect(origin: CGPoint.zero, size: decoratorLabel.intrinsicContentSize)
        titleLabel?.frame.origin.x += decoratorLabel.intrinsicContentSize.width
        addSubview(decoratorLabel)
    }
}
