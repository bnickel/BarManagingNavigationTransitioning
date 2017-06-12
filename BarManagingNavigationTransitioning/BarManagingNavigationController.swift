//
//  BarManagingNavigationController.swift
//  BarManagingNavigationTransitioning
//
//  Created by Brian Nickel on 6/12/17.
//  Copyright © 2017 Brian Nickel. All rights reserved.
//

import UIKit

class BarManagingNavigationController: UINavigationController {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        navigationBar.isTranslucent = false
        delegate = self
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
        self.setNavigationBarHidden(viewController.hidesNavigationBar, animated: animated)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BarManagingNavigationAnimatedTranistioning(navigationController: self, operation: operation)
    }
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

extension BarManagingNavigationAnimatedTranistioning: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from)
            else { transitionContext.completeTransition(!transitionContext.transitionWasCancelled); return }
        
        dump(navigationController.view.frame, name: "Navigation Frame")
        dump(transitionContext.containerView.frame, name: "Container Frame")
        dump(transitionContext.initialFrame(for: from), name: "From Initial Frame")
        dump(transitionContext.finalFrame(for: to), name: "To Final Frame")
        
        to.view.frame = finalFrame(for: to, in: transitionContext)
        to.view.layoutIfNeeded()
        transitionContext.containerView.addSubview(to.view)
        transitionContext.completeTransition(true)
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
    }
}
