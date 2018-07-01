//
//  TagController.swift
//  Foodlog
//
//  Created by David on 2/23/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class TagController: NSObject {
    var tagsView: FlowContainerView!
    private static let shadowDuration = 0.4
    private static let shadowRelativeDuration = shadowDuration / animationDuration
    private static let translationDuration = 0.4
    private static let translationRelativeDuration = translationDuration / animationDuration
    private static let animationDuration = shadowDuration + translationDuration
    private var context: TagControllerContext!
    private var viewForEmpty: UIView!
    private var viewForTag = [String: UIView]()
    
    func setup(_ context: TagControllerContext) {
        func makeFill(nonempty: @escaping (Tag) -> UIView) -> (AnyCollection<Tag>) -> () {
            return { [tagsView, weak self] tags in
                tags.map({ ($0.name, nonempty($0)) }).forEach({
                    tagsView!.addSubview($0.1)
                    self!.viewForTag[$0.0] = $0.1
                })
            }
        }
        
        self.context = context
        let fill: (AnyCollection<Tag>) -> ()
        switch context.presentation {
        case .disabled:
            fill = makeFill { $0.disabledButton }
            viewForEmpty = {
                let label = UILabel()
                label.textColor = .lightGray
                label.text = "no tags"
                label.translatesAutoresizingMaskIntoConstraints = false
                let padderView = UIView()
                padderView.translatesAutoresizingMaskIntoConstraints = false
                padderView.addSubview(label)
                NSLayoutConstraint.activate([
                    padderView.topAnchor.constraint(equalTo: label.topAnchor),
                    padderView.bottomAnchor.constraint(equalTo: label.bottomAnchor),
                    padderView.leftAnchor.constraint(equalTo: label.leftAnchor, constant: -6.0),
                    padderView.rightAnchor.constraint(equalTo: label.rightAnchor)
                    ])
                return padderView
            }()
        case .enabled(let titleForEmpty):
            fill = makeFill {
                let button = $0.activeButton
                button.addTarget(self, action: #selector(TagController.tagPressed), for: .touchUpInside)
                return button
            }
            viewForEmpty = {
                let button = UIButton(pillFilled: titleForEmpty, color: .lightGray)
                button.addTarget(self, action: #selector(TagController.tagPressed), for: .touchUpInside)
                return button
            }()
        }
        
        if context.tags.isEmpty {
            tagsView.addSubview(viewForEmpty)
            viewForTag[""] = viewForEmpty
        } else {
            fill(context.tags)
        }
        
        context.onTagAdded { [tagsView, viewForEmpty, weak self] in
            let view = $0.makeControlButton(toggled: true, self!, #selector(self!.tagPressed))
            self!.viewForTag[$0.name] = view
            tagsView!.addSubview(view)
            if self!.viewForTag[""] != nil {
                viewForEmpty!.removeFromSuperview()
                self!.viewForTag[""] = nil
            }
        }
        context.onTagRemoved { [tagsView, viewForEmpty, weak self] in
            self!.viewForTag[$0]!.removeFromSuperview()
            self!.viewForTag[$0] = nil
            if self!.viewForTag.isEmpty {
                tagsView!.addSubview(viewForEmpty!)
                self!.viewForTag[""] = viewForEmpty!
            }
        }
    }
    
    @objc private func tagPressed() {
        VCController.showTags(context: context, transitioning: self)
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
            let view2 = transitionContext.containerView
            return (view.leftAnchor.constraint(equalTo: view2.leftAnchor, constant: left),
                    view.rightAnchor.constraint(equalTo: view2.rightAnchor, constant: right),
                    view.heightAnchor.constraint(equalToConstant: height),
                    view.centerYAnchor.constraint(equalTo: view2.centerYAnchor, constant: centerY))
        }
        
        if let toVC = transitionContext.viewController(forKey: .to) as? TagsViewController {
            let animatedView = makeAnimatedView()
            animatedView.alpha = 0.0
            transitionContext.containerView.addSubview(animatedView)
            
            let startFrame = tagsView.convert(tagsView.bounds, to: nil)
            let (left, right, height, centerY) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: startFrame.height,
                                centerY: startFrame.midY - toVC.view.frame.height/2)
            NSLayoutConstraint.activate([left, right, height, centerY])
            transitionContext.containerView.layoutIfNeeded()
            
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.shadowRelativeDuration,
                                   animations: { animatedView.alpha = 1.0 })
                UIView.addKeyframe(withRelativeStartTime: TagController.shadowRelativeDuration,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    height.constant = 214.0
                    centerY.constant = -23.0
                    transitionContext.containerView.layoutIfNeeded()
                }
            }) { _ in
                toVC.view.alpha = 0.0
                transitionContext.containerView.addSubview(toVC.view)
                animatedView.alpha = 0.0
                toVC.view.alpha = 1.0
                transitionContext.completeTransition(true)
            }
            
        } else if let fromVC = transitionContext.viewController(forKey: .from) as? TagsViewController {
            transitionContext.containerView.subviews.forEach { $0.removeFromSuperview() }
            
            let animatedView = makeAnimatedView()
            transitionContext.containerView.addSubview(animatedView)
            
            let (left, right, height, centerY) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: 214.0, centerY: -23.0)
            NSLayoutConstraint.activate([left, right, height, centerY])
            transitionContext.containerView.layoutIfNeeded()
            
            let endFrame = tagsView.convert(tagsView.bounds, to: nil)
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    height.constant = endFrame.height
                    centerY.constant = endFrame.midY - fromVC.view.frame.height/2
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
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension TagController {
    enum Presentation {
        case disabled
        case enabled(String)
    }
    
    class Common {
        var tagAdded: (Tag) -> () = { _ in }
        var tagRemoved: (String) -> () = { _ in }
    }
    
    final class DisabledFood: Common {
        private let food: Food
        
        init(_ food: Food) {
            self.food = food
        }
    }
    
    final class EnabledExistingFood: Common {
        private let food: Food
        private let changes: Changes<Food>
        
        init(_ food: Food, _ changes: Changes<Food>) {
            self.food = food
            self.changes = changes
        }
    }
    
    final class EnabledNewFood: Common {
        private let food: Food
        
        init(_ food: Food) {
            self.food = food
        }
    }
    
    final class ExistingFoodEntry: Common {
        private let foodEntry: FoodEntry
        private let changes: Changes<FoodEntry>
        
        init(_ foodEntry: FoodEntry, _ changes: Changes<FoodEntry>) {
            self.foodEntry = foodEntry
            self.changes = changes
        }
    }
    
    final class NewFoodEntry: Common {
        private let foodEntry: FoodEntry
        
        init(_ foodEntry: FoodEntry) {
            self.foodEntry = foodEntry
        }
    }
}

protocol TagControllerContext: class {
    var presentation: TagController.Presentation { get }
    var tags: AnyCollection<Tag> { get }
    func onTagAdded(_ block: @escaping (Tag) -> ())
    func onTagRemoved(_ block: @escaping (String) -> ())
    func updatedTags(_ changes: [String: Tag.Change])
}

extension TagControllerContext where Self: TagController.Common {
    func onTagAdded(_ block: @escaping (Tag) -> ()) {
        tagAdded = block
    }
    
    func onTagRemoved(_ block: @escaping (String) -> ()) {
        tagRemoved = block
    }
}

extension TagController.DisabledFood: TagControllerContext {
    var presentation: TagController.Presentation {
        return .disabled
    }
    var tags: AnyCollection<Tag> {
        return AnyCollection(food.tags)
    }
    
    func updatedTags(_ changes: [String: Tag.Change]) {
        assert(changes == [:])
    }
}

extension TagController.EnabledExistingFood: TagControllerContext {
    var presentation: TagController.Presentation {
        return .enabled("add tag for food")
    }
    var tags: AnyCollection<Tag> {
        return AnyCollection(food.tags)
    }
    
    func updatedTags(_ changes: [String: Tag.Change]) {
        guard changes != [:] else { return }
        food.tagsChanged(changes, added: tagAdded, removed: tagRemoved)
        self.changes.insert(change: \Food.tagsCKReferences)
    }
}

extension TagController.EnabledNewFood: TagControllerContext {
    var presentation: TagController.Presentation {
        return .enabled("add tag for food")
    }
    var tags: AnyCollection<Tag> {
        return AnyCollection(food.tags)
    }
    
    func updatedTags(_ changes: [String: Tag.Change]) {
        food.tagsChanged(changes, added: tagAdded, removed: tagRemoved)
    }
}

extension TagController.ExistingFoodEntry: TagControllerContext {
    var presentation: TagController.Presentation {
        return .enabled("add tag for entry")
    }
    var tags: AnyCollection<Tag> {
        return AnyCollection(foodEntry.tags)
    }
    
    func updatedTags(_ changes: [String: Tag.Change]) {
        guard changes != [:] else { return }
        foodEntry.tagsChanged(changes, added: tagAdded, removed: tagRemoved)
        self.changes.insert(change: \FoodEntry.tagsCKReferences)
    }
}

extension TagController.NewFoodEntry: TagControllerContext {
    var presentation: TagController.Presentation {
        return .enabled("add tag for entry")
    }
    var tags: AnyCollection<Tag> {
        return AnyCollection(foodEntry.tags)
    }
    
    func updatedTags(_ changes: [String: Tag.Change]) {
        foodEntry.tagsChanged(changes, added: tagAdded, removed: tagRemoved)
    }
}

extension Food {
    fileprivate func tagsChanged(_ changes: [String: Tag.Change], added: (Tag) -> (), removed: (String) -> ()) {
        for (name, change) in changes {
            switch change {
            case .added:
                let tag = Tag(value: DataStore.tags.first(where: { $0.name == name })!)
                tag.searchSuggestion = SearchSuggestion(value: tag.searchSuggestion!)
                tag.searchSuggestion!.lastUsed = Date()
                tags.append(tag)
                added(tag)
            case .removed:
                tags.remove(at: tags.index(where: { $0.name == name })!)
                removed(name)
            case .unchanged:
                fatalError()
            }
        }
    }
}

extension FoodEntry {
    fileprivate func tagsChanged(_ changes: [String: Tag.Change], added: (Tag) -> (), removed: (String) -> ()) {
        for (name, change) in changes {
            switch change {
            case .added:
                let tag = Tag(value: DataStore.tags.first(where: { $0.name == name })!)
                tag.searchSuggestion = SearchSuggestion(value: tag.searchSuggestion!)
                tag.searchSuggestion!.lastUsed = Date()
                tags.append(tag)
                added(tag)
            case .removed:
                tags.remove(at: tags.index(where: { $0.name == name })!)
                removed(name)
            case .unchanged:
                fatalError()
            }
        }
    }
}

final class TagsViewController: UIViewController {
    @IBOutlet weak var addTagContainerView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagsView: FlowContainerView!
    
    var context: TagControllerContext!
    private var statusForTag = [String: Tag.Change]()
    
    override func viewDidLoad() {
        for tag in context.tags {
            statusForTag[tag.name] = .unchanged
        }
        
        for tag in DataStore.tags {
            tagsView.addSubview(tag.makeControlButton(toggled: statusForTag[tag.name] != nil, self,
                                                      #selector(toggleTag(_:))))
        }
        let button = UIButton(pillFilled: "add new tag", color: .lightGray)
        button.addTarget(self, action: #selector(startAddNewTag), for: .touchUpInside)
        tagsView.addSubview(button)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    func showAddTag(view addTagView: UIView) {
        addTagView.layer.cornerRadius = 16.0
        addTagContainerView.embedSubview(addTagView)
        addTagContainerView.alpha = 0.0
        addTagContainerView.isHidden = false
        UIView.animate(withDuration: 0.2, animations: { [addTagContainerView] in addTagContainerView!.alpha = 1.0 })
    }
    
    func dismissAddTag(view addTagView: UIView, newTag: Tag?) {
        if let tag = newTag {
            tagsView.addSubview(tag.makeControlButton(toggled: false, self, #selector(toggleTag(_:))))
        }
        UIView.animate(withDuration: 0.2,
                       animations: { [addTagContainerView] in addTagContainerView!.alpha = 0.0 })
        { [addTagContainerView, view] _ in
            addTagView.removeFromSuperview()
            addTagContainerView!.isHidden = true
            addTagContainerView!.alpha = 1.0
            UIView.animate(withDuration: 0.2, animations: { view!.layoutIfNeeded() })
        }
    }
    
    @IBAction func dismiss() {
        context.updatedTags(statusForTag.filter { $0.1 != .unchanged })
        VCController.dismissTags()
    }
    
    @objc private func keyboardWasShown(_ aNotification: NSNotification) {
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        bottomConstraint.constant = 16.0 + keyboardFrame.height
        UIView.animate(withDuration: 0.3) { [view] in view!.layoutIfNeeded() }
    }
    
    @objc private func keyboardWillBeHidden() {
        bottomConstraint.constant = 0.0
        UIView.animate(withDuration: 0.3) { [view] in view!.layoutIfNeeded() }
    }
    
    @objc private func toggleTag(_ sender: DualLabelButton) {
        guard let name = sender.currentTitle else { return }
        let status: Tag.Change?, leftTitle: String
        switch statusForTag[name] {
        case .added?:       status = nil;           leftTitle = "+"
        case .removed?:     status = .unchanged;    leftTitle = "×"
        case .unchanged?:   status = .removed;      leftTitle = "+"
        case .none:         status = .added;        leftTitle = "×"
        }
        
        statusForTag[name] = status
        let color = sender.backgroundColor
        UIView.animate(withDuration: 0.2, animations: { sender.backgroundColor = .white }) { _ in
            sender.setLeftTitle(leftTitle)
            UIView.animate(withDuration: 0.2, animations: { sender.backgroundColor = color })
        }
    }
    
    @objc private func startAddNewTag() {
        VCController.addTag(parent: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Tag {
    enum Change {
        case added
        case removed
        case unchanged
    }
    
    fileprivate func makeControlButton(toggled: Bool, _ target: Any, _ action: Selector) -> DualLabelButton {
        let button = toggled ? DualLabelButton(pillLeft: "×", right: name, color: color) :
            DualLabelButton(pillLeft: "+", right: name, color: color)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}

final class DualLabelButton: UIButton {
    override var intrinsicContentSize: CGSize {
        let width = contentEdgeInsets.left + leftLabel.intrinsicContentSize.width + 3.0 +
            titleLabel!.intrinsicContentSize.width + contentEdgeInsets.right
        let height = contentEdgeInsets.bottom + titleLabel!.intrinsicContentSize.height + contentEdgeInsets.top
        return CGSize(width: width, height: height)
    }

    private static let caseSensitiveFont: UIFont = {
        let descriptor = UIFont.systemFont(ofSize: 14.0).fontDescriptor.addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kCaseSensitiveLayoutType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kCaseSensitiveLayoutOnSelector
                ]
            ]
            ])
        return UIFont(descriptor: descriptor, size: 0.0)
    }()
    private let leftLabel = UILabel()
    
    convenience init(pillLeft left: String, right: String, color: UIColor) {
        self.init(pillFilled: right, color: color)
        leftLabel.font = DualLabelButton.caseSensitiveFont
        leftLabel.isUserInteractionEnabled = true
        leftLabel.text = left
        leftLabel.textColor = currentTitleColor
        addSubview(leftLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        leftLabel.frame = CGRect(origin: CGPoint(x: contentEdgeInsets.left, y: contentEdgeInsets.top),
                                 size: leftLabel.intrinsicContentSize)
        titleLabel?.frame = CGRect(origin: CGPoint(x: leftLabel.frame.origin.x+leftLabel.frame.width+3.0,
                                                   y: titleLabel!.frame.origin.y),
                                   size: titleLabel!.intrinsicContentSize)
    }
    
    func setLeftTitle(_ title: String) {
        leftLabel.text = title
        layoutIfNeeded()
    }
}
