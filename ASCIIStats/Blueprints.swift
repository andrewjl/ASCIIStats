//
//  Blueprints.swift
//  ASCIIStats
//
//  Created by Andrew Lauer Barinov on 10/30/20.
//

import UIKit

public struct ReactiveElement<UnderlyingElement, State> {
    var element: UnderlyingElement
    var strongReferences: [Any]
    var update: (State, State) -> ()
}

public typealias Change<State> = (inout State) -> ()

public struct PresentationContext<State> {
    let state: State
    let reduce: ((inout State) -> ()) -> ()
    let pushViewController: (UIViewController) -> ()
    let popViewController: () -> ()
}

final class TargetAction {
    let execute: () -> ()
    init(_ execute: @escaping () -> ()) {
        self.execute = execute
    }
    
    @objc func action(_ sender: Any) {
        self.execute()
    }
}

final class SenderAttachedTargetAction {
    let execute: (Any) -> ()
    init(_ execute: @escaping (Any) -> ()) {
        self.execute = execute
    }
    
    @objc func action(_ sender: Any) {
        self.execute(sender)
    }
}

public typealias Blueprint<UnderlyingElement, A> = (PresentationContext<A>) -> ReactiveElement<UnderlyingElement, A>

// MARK: Blueprints: Controls

typealias Transformer<A> = (A) -> (A)

func label<State>(keyPath: KeyPath<State, String>,
                     font: UIFont? = nil,
              transformer: Transformer<String>? = nil,
            textAlignment: NSTextAlignment = .natural,
             minimumWidth: CGFloat? = nil) -> Blueprint<UIView, State> {
    return { context in
        let label = UILabel(frame: CGRect.zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = textAlignment
        
        if let f = font {
            label.font = f
        }
        
        if let mw = minimumWidth {
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: mw).isActive = true
        }
        
        return ReactiveElement(element: label,
                      strongReferences: [],
                                update: { (oldState, updatedState) in
            if let tr = transformer {
                label.text = tr(updatedState[keyPath: keyPath])
            } else {
                label.text = updatedState[keyPath: keyPath]
            }
        })
    }
}

// This does not require the generic parameter, but one
// is still needed to satisfy the type checker
func placeholderLabel<State>(title: String,
                             font: UIFont? = nil,
                             textAlignment: NSTextAlignment = .natural,
                             minimumWidth: CGFloat? = nil) -> Blueprint<UIView, State> {
    return { context in
        let label = UILabel()
        label.text = title
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = textAlignment
        
        if let f = font {
            label.font = f
        }
        
        if let mw = minimumWidth {
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: mw).isActive = true
        }
        
        return ReactiveElement(element: label,
                               strongReferences: [],
                               update: noOpUpdate())
    }
}

typealias ChangeKeypath<State> = KeyPath<State, Change<State>>

// We make this explicit
// A lack of an update is somewhat of a code smell
// Does a static reactive element struct need an update?
func noOpUpdate<State>() -> (State, State) -> () {
    return { (priorState:State, updatedState:State) in
        // No-op
    }
}

func action<State>(changeKeypath: ChangeKeypath<State>) -> Blueprint<UIAction, State> {
    return { context in
        let a = UIAction { (act:UIAction) in
            // Achieve dynamism by swapping out the contents of the keypath
            context.reduce { (mutableState:inout State) in
                mutableState[keyPath: changeKeypath](&mutableState)
            }
        }
        
        return ReactiveElement(element: a,
                               strongReferences: [],
                               update: noOpUpdate())
    }
}

func button<State>(title: String,
                    font: UIFont? = nil,
                  action: @escaping Blueprint<UIAction, State>) -> Blueprint<UIView, State> {
    return { context in
        let reactiveAction = action(context)
        
        let button = UIButton(primaryAction: reactiveAction.element)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        
        if let f = font {
            button.titleLabel?.font = f
        }
        
        return ReactiveElement(element: button,
                               strongReferences: reactiveAction.strongReferences,
                               update: noOpUpdate())
    }
}

class DisplayLinkHolder {
    var displayLink: CADisplayLink
    
    init(displayLink: CADisplayLink) {
        self.displayLink = displayLink
    }
    
    func start() {
        self.displayLink.add(to: .main,
                             forMode: .default)
    }
    
    func stop() {
        self.displayLink.remove(from: .main,
                                forMode: .default)
    }
}

func displayLink<State>(activeKeyPath: KeyPath<State, Bool>,
                        tickKeyPath: KeyPath<State, Change<State>>) -> Blueprint<DisplayLinkHolder, State> {
    return { context in
        let ta = TargetAction {
            context.reduce { $0[keyPath: tickKeyPath](&$0) }
        }
        
        let d = CADisplayLink(target: ta,
                              selector: #selector(TargetAction.action(_:)))
        d.preferredFramesPerSecond = 15
        let h = DisplayLinkHolder(displayLink: d)
        
        return ReactiveElement(element: h,
                               strongReferences: [ta],
                               update: { (priorState: State, updatedState: State) in
            if priorState[keyPath: activeKeyPath] == false && updatedState[keyPath: activeKeyPath] == true {
                h.start()
            }
                                
            if priorState[keyPath: activeKeyPath] == true && updatedState[keyPath: activeKeyPath] == false {
                h.stop()
            }
        })
    }
}

// MARK: Blueprints: Stack Views

func verticalStackView<State>(views: [Blueprint<UIView, State>],
                              spacing: CGFloat = 5.0,
                              distribution: UIStackView.Distribution = .equalSpacing,
                              layoutMargins: UIEdgeInsets = .zero) -> Blueprint<UIView, State> {
    return { context in
        
        let reactiveElements = views.map { $0(context) }
        let subviews = reactiveElements.compactMap { $0.element }
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.distribution = distribution
        stackView.axis = .vertical
        stackView.spacing = spacing
        if layoutMargins != .zero {
            stackView.isLayoutMarginsRelativeArrangement = true
        }
        stackView.layoutMargins = layoutMargins
        
        let update: (State, State) -> () = { (oldState, updatedState) in
            for c in reactiveElements {
                c.update(oldState, updatedState)
            }
        }
        
        return ReactiveElement(element: stackView,
                               strongReferences: reactiveElements.compactMap { $0.strongReferences},
                               update: update)
    }
}

func horizontalStackView<State>(views: [Blueprint<UIView, State>],
                                distribution: UIStackView.Distribution = .equalSpacing,
                                spacing: CGFloat = 5.0) -> Blueprint<UIView, State> {
    return { context in
        
        let reactiveElements = views.map { $0(context) }
        let subviews = reactiveElements.compactMap { $0.element }
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.distribution = distribution
        stackView.axis = .horizontal
        stackView.spacing = spacing
        
        let update: (State, State) -> () = { (oldState, updatedState) in
            for c in reactiveElements {
                c.update(oldState, updatedState)
            }
        }
        
        return ReactiveElement(element: stackView,
                               strongReferences: reactiveElements.compactMap { $0.strongReferences},
                               update: update)
    }
}


// MARK: Blueprints: View Controller

func randomnessViewController() -> Blueprint<UIViewController, RandomnessRun> {
    return { context in
        let viewController = RandomnessViewController()
        
        let titleFont = UIFont.preferredFont(forTextStyle: .subheadline).withSize(28.0)
        let stackViewLayoutMargins = UIEdgeInsets(top: 48,
                                                  left: 8,
                                                  bottom: 48,
                                                  right: 8)
        
        let outcomeDistributionStackView = verticalStackView(views: [
            placeholderLabel(title: "Outcome Distribution",
                            font: titleFont),
            label(keyPath: \RandomnessRun.starredHeads,
                  font: UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0)),
            label(keyPath: \RandomnessRun.starredTails,
                  font: UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0))
        ], layoutMargins: stackViewLayoutMargins)(context)
        
        let trueProbabilitiesStackView = verticalStackView(views: [
            placeholderLabel(title: "True Probabilities",
                            font: titleFont),
            label(keyPath: \RandomnessRun.probabilityDistributionHeads,
                  font: UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0)),
            label(keyPath: \RandomnessRun.probabilityDistributionTails,
                  font: UIFont.preferredFont(forTextStyle: .subheadline).withSize(18.0))
        ], layoutMargins: stackViewLayoutMargins)(context)
        
        let flipOnceButton = button(title: "Flip Once", action: action(changeKeypath: \RandomnessRun.flipAction))(context)
        let flipHundredTimesButton = button(title: "Flip 100 Times", action: action(changeKeypath: \RandomnessRun.flipHundredTimesAction))(context)
        
        let displayLinkHolder = displayLink(activeKeyPath: \RandomnessRun.isTicking,
                                            tickKeyPath: \RandomnessRun.tickAction)(context)
        
        viewController.displayLinkHolder = displayLinkHolder.element
        
        viewController.view.addSubview(outcomeDistributionStackView.element)
        viewController.view.addSubview(trueProbabilitiesStackView.element)
        viewController.view.addSubview(flipOnceButton.element)
        viewController.view.addSubview(flipHundredTimesButton.element)
        
        // Layout views here
        
        outcomeDistributionStackView.element.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor).isActive = true
        outcomeDistributionStackView.element.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        outcomeDistributionStackView.element.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        outcomeDistributionStackView.element.bottomAnchor.constraint(equalTo: trueProbabilitiesStackView.element.topAnchor).isActive = true
        outcomeDistributionStackView.element.heightAnchor.constraint(equalTo: viewController.view.heightAnchor,
                                                                     multiplier: 0.33333).isActive = true
        
        trueProbabilitiesStackView.element.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        trueProbabilitiesStackView.element.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        trueProbabilitiesStackView.element.heightAnchor.constraint(equalTo: outcomeDistributionStackView.element.heightAnchor).isActive = true
        
        flipHundredTimesButton.element.topAnchor.constraint(equalTo: flipOnceButton.element.topAnchor).isActive = true
        flipOnceButton.element.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor,
                                                       constant: -16.0).isActive = true
        flipHundredTimesButton.element.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor,
                                                               constant: -16.0).isActive = true
        flipOnceButton.element.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor,
                                                        constant: 16.0).isActive = true
        flipHundredTimesButton.element.leadingAnchor.constraint(equalTo: flipOnceButton.element.trailingAnchor,
                                                                constant: 16.0).isActive = true
        
        let strongReferences = outcomeDistributionStackView.strongReferences + trueProbabilitiesStackView.strongReferences + flipOnceButton.strongReferences + flipHundredTimesButton.strongReferences + displayLinkHolder.strongReferences
        
        return ReactiveElement(element: viewController,
                               strongReferences: strongReferences,
                               update: { (priorState: RandomnessRun, updatedState: RandomnessRun) in
            displayLinkHolder.update(priorState, updatedState)
            outcomeDistributionStackView.update(priorState, updatedState)
            trueProbabilitiesStackView.update(priorState, updatedState)
            flipOnceButton.update(priorState, updatedState)
            flipHundredTimesButton.update(priorState, updatedState)
        })
    }
}
