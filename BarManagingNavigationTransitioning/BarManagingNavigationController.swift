//
//  BarManagingNavigationController.swift
//  BarManagingNavigationTransitioning
//
//  Created by Brian Nickel on 6/12/17.
//  Copyright © 2017 Brian Nickel. All rights reserved.
//

import UIKit

class BarManagingNavigationController: UINavigationController {
    
    fileprivate var activeInteractiveTransition: NavigationPercentDrivenInteractiveTransition?
    fileprivate var navigationPopGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var navigationPopGestureRecognizerDelegate: GestureRecognizerDelegate?
    
    override init(rootViewController: UIViewController?) {
        super.init(nibName: nil, bundle: nil)
        configure()
        if let rootViewController = rootViewController {
            viewControllers = [rootViewController]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    private func configure() {
        navigationBar.isTranslucent = false
        delegate = self
        
        let gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.respondToNavigationPopGestureRecognizer(_:)))
        gestureRecognizer.edges = .left
        
        navigationPopGestureRecognizerDelegate = GestureRecognizerDelegate(navigationController: self)
        gestureRecognizer.delegate = navigationPopGestureRecognizerDelegate
        
        view.addGestureRecognizer(gestureRecognizer)
        navigationPopGestureRecognizer = gestureRecognizer
    }
    
    override var delegate: UINavigationControllerDelegate? {
        willSet {
            precondition(delegate === newValue || newValue === self, "BarManagingNavigationController can only have itself as a delegate.")
        }
    }
}

extension BarManagingNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if isNavigationBarHidden && !viewController.hidesNavigationBar {
            setNavigationBarHidden(false, animated: false)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        setNavigationBarHidden(viewController.hidesNavigationBar, animated: false)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BarManagingNavigationAnimatedTranistioning(navigationController: self, operation: operation)
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if navigationPopGestureRecognizer?.state == .began {
            let transition = NavigationPercentDrivenInteractiveTransition()
            activeInteractiveTransition = transition
            return transition
        } else {
            return nil
        }
    }
    
    @objc(SEUI_respondToNavigationPopGestureRecognizer:) fileprivate func respondToNavigationPopGestureRecognizer(_ sender: UIScreenEdgePanGestureRecognizer) {
        switch sender.state {
            
        case .began:
            _ = popViewController(animated: true)
            
        case .changed:
            activeInteractiveTransition?.update(sender.translation(in: view).x / view.bounds.width)
            
        case .cancelled:
            activeInteractiveTransition?.completionCurve = .linear
            activeInteractiveTransition?.completionSpeed = 1
            activeInteractiveTransition?.cancel()
            activeInteractiveTransition = nil
            
        case .ended:
            if let activeInteractiveTransition = activeInteractiveTransition {
                activeInteractiveTransition.completionSpeed = 1
                if sender.velocity(in: view).x > 0 && activeInteractiveTransition.hasInteractedRecently || activeInteractiveTransition.percentComplete > 0.6 {
                    activeInteractiveTransition.completionCurve = .easeOut
                    activeInteractiveTransition.finish()
                } else {
                    activeInteractiveTransition.completionCurve = .linear
                    activeInteractiveTransition.cancel()
                }
            }
            activeInteractiveTransition = nil
            
        default:
            break
            
        }
    }
    
    fileprivate class GestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
        unowned var navigationController: UINavigationController
        
        init(navigationController: UINavigationController) {
            self.navigationController = navigationController
        }
        
        fileprivate func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard
                navigationController.transitionCoordinator == nil,
                navigationController.viewControllers.count > 1
                else { return false }
            return true
        }
        
        fileprivate func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
    }
}

class NavigationPercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition {
    private var lastUpdateTime = Date.timeIntervalSinceReferenceDate
    var recentInteractionCutoff: TimeInterval = 0.25
    
    override func update(_ percentComplete: CGFloat) {
        super.update(percentComplete)
        lastUpdateTime = Date.timeIntervalSinceReferenceDate
    }
    
    var hasInteractedRecently: Bool { return Date.timeIntervalSinceReferenceDate - lastUpdateTime < recentInteractionCutoff }
}

extension UIViewController {
    
    private static var hidesNavigationBarKey = 0
    
    @objc(SEUI_hidesNavigationBar) var hidesNavigationBar: Bool {
        get {
            return objc_getAssociatedObject(self, &UIViewController.hidesNavigationBarKey) as? Bool ?? false
        }
        set {
            setHidesNavigationBar(newValue, animated: false)
        }
    }
    
    @objc(SEUI_setHidesNavigationBar:animated:) func setHidesNavigationBar(_ newValue: Bool, animated: Bool) {
        
        guard newValue != hidesNavigationBar else { return }
        
        objc_setAssociatedObject(self, &UIViewController.hidesNavigationBarKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        if navigationController?.topViewController == self && transitionCoordinator == nil {
            navigationController?.setNavigationBarHidden(newValue, animated: animated)
        }
    }
}

class BarManagingNavigationAnimatedTranistioning: NSObject {
    let navigationController: UINavigationController
    let operation: UINavigationControllerOperation
    
    init(navigationController: UINavigationController, operation: UINavigationControllerOperation) {
        self.navigationController = navigationController
        self.operation = operation
        super.init()
    }
}

extension BarManagingNavigationAnimatedTranistioning {
    
    /* In all cases, the transition context view will cover the entire navigation controller, including the space under the bar.
     *
     * The only time a frame returned by the transition context is incorrect is the the final frame when going from visible to hidden.
     * This is because we keep the navigation bar visible during this transition to animate it.  In this case, we simply give the top inset back
     * to the frame.
     *
     */
    
    fileprivate func initialFrame(for from: UIViewController, in transitionContext: UIViewControllerContextTransitioning) -> CGRect {
        return transitionContext.initialFrame(for: from)
    }
    
    fileprivate func finalFrame(for to: UIViewController, in transitionContext: UIViewControllerContextTransitioning) -> CGRect {
        var frame = transitionContext.finalFrame(for: to)
        if to.hidesNavigationBar {
            frame.size.height += frame.origin.y
            frame.origin.y = 0
        }
        return frame
    }
}

private extension CGRect {
    static func offScreenRight(_ rect: CGRect) -> CGRect {
        return rect.offsetBy(dx: rect.width, dy: 0)
    }
    
    static func underNavigationStack(_ rect: CGRect) -> CGRect {
        return rect.offsetBy(dx: -rect.width / 2, dy: 0)
    }
}

extension BarManagingNavigationAnimatedTranistioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from)
            else { transitionContext.completeTransition(!transitionContext.transitionWasCancelled); return }
        
        let fromInitialFrame = initialFrame(for: from, in: transitionContext)
        let toFinalFrame = finalFrame(for: to, in: transitionContext)
        
        let maskView = UIView(frame: fromInitialFrame.union(toFinalFrame))
        maskView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3037243151)
        
        let fromFinalFrameTransform: (CGRect) -> CGRect
        let toInitialFrameTransform: (CGRect) -> CGRect
        let maskAlpha: (initial: CGFloat, final: CGFloat)
        let topView: UIView
        
        switch operation {
            
        case .push:
            fromFinalFrameTransform = CGRect.underNavigationStack
            toInitialFrameTransform = CGRect.offScreenRight
            maskAlpha = (0, 1)
            topView = to.view
            
        case .pop:
            fromFinalFrameTransform = CGRect.offScreenRight
            toInitialFrameTransform = CGRect.underNavigationStack
            maskAlpha = (1, 0)
            topView = from.view
            
        case .none:
            fromFinalFrameTransform = { $0 }
            toInitialFrameTransform = { $0 }
            maskAlpha = (0, 0)
            topView = to.view
        }
        
        var transitions: [Transition] = [
            FrameTransition(view: from.view, initial: fromInitialFrame,                      final: fromFinalFrameTransform(fromInitialFrame)),
            FrameTransition(view: to.view,   initial: toInitialFrameTransform(toFinalFrame), final: toFinalFrame),
            AlphaTransition(view: maskView,  initial: maskAlpha.initial,                     final: maskAlpha.final)
        ]
        
        transitionContext.containerView.addSubview(to.view)
        transitionContext.containerView.addSubview(maskView)
        transitionContext.containerView.bringSubview(toFront: topView)
        
        let navigationBarParentView = UIView(frame: transitionContext.containerView.bounds)
        let navigationBarOriginalParentView = navigationController.navigationBar.superview
        
        if to.hidesNavigationBar != from.hidesNavigationBar {
            
            navigationBarParentView.addSubview(navigationController.navigationBar)
            
            if to.hidesNavigationBar {
                transitionContext.containerView.insertSubview(navigationBarParentView, aboveSubview: from.view)
                transitions.append(FrameTransition(view: navigationBarParentView, initial: navigationBarParentView.frame, final: fromFinalFrameTransform(navigationBarParentView.frame)))
            } else {
                transitionContext.containerView.insertSubview(navigationBarParentView, aboveSubview: to.view)
                transitions.append(FrameTransition(view: navigationBarParentView, initial: toInitialFrameTransform(navigationBarParentView.frame), final: navigationBarParentView.frame))
            }
        }
        
        for transition in transitions {
            transition.start()
        }
        
        let options: UIViewAnimationOptions = transitionContext.isInteractive ? .curveLinear : .curveEaseOut
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: options, animations: {
            for transition in transitions {
                transition.end()
            }
            
        }, completion: { finished in
            
            for view in navigationBarParentView.subviews {
                navigationBarOriginalParentView?.addSubview(view)
            }
            navigationBarParentView.removeFromSuperview()
            maskView.removeFromSuperview()
            
            if transitionContext.transitionWasCancelled {
                to.view.removeFromSuperview()
                self.navigationController.setNavigationBarHidden(from.hidesNavigationBar, animated: false)
                transitionContext.completeTransition(false)
            } else {
                from.view.removeFromSuperview()
                self.navigationController.setNavigationBarHidden(to.hidesNavigationBar, animated: false)
                transitionContext.completeTransition(true)
            }
        })
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
    }
}

private protocol Transition {
    func start()
    func end()
}

private struct FrameTransition: Transition {
    let view: UIView
    let initial: CGRect
    let final: CGRect
    
    func start() { view.frame = initial }
    func end() { view.frame = final }
}

private struct AlphaTransition: Transition {
    let view: UIView
    let initial: CGFloat
    let final: CGFloat
    
    func start() { view.alpha = initial }
    func end() { view.alpha = final }
}
