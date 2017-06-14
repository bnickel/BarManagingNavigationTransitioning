//
//  BarManagingSplitViewController.swift
//  BarManagingNavigationTransitioning
//
//  Created by Brian Nickel on 6/13/17.
//  Copyright © 2017 Brian Nickel. All rights reserved.
//

import UIKit

class BarManagingSplitViewController: UISplitViewController {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // This is just a sad attempt to capture first appearance.
        if !animated {
            showMasterViewController()
            if viewControllers.count == 1 {
                viewControllers.append(placeholderViewController)
            }
        }
    }
    
    fileprivate var loadedPlaceholderViewController: UIViewController?
    
    var placeholderViewController: UIViewController {
        get {
            if let placeholderViewController = loadedPlaceholderViewController { return placeholderViewController }
            let placeholderViewController = loadPlaceholderViewController()
            loadedPlaceholderViewController = placeholderViewController
            return placeholderViewController
        }
        set {
            loadedPlaceholderViewController = newValue
        }
    }
    
    var isPlaceholderViewControllerLoaded: Bool { return loadedPlaceholderViewController != nil }
    
    open func loadPlaceholderViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.navigationItem.leftBarButtonItem = displayModeButtonItem
        return BarManagingNavigationController(rootViewController: viewController)
    }
}

extension UISplitViewController {
    
    @objc(SEUI_masterViewController) var masterViewController: UIViewController? {
        return viewControllers.first
    }
    
    @objc(SEUI_showMasterViewController) func showMasterViewController() {
        guard let target = displayModeButtonItem.target, let action = displayModeButtonItem.action else { return }
        UIApplication.shared.sendAction(action, to: target, from: displayModeButtonItem, for: nil)
    }
}

extension UIViewController {
    private static var isDetailViewControllerKey = 0
    
    @objc(SEUI_isDetailViewController) fileprivate(set) var isDetailViewController: Bool {
        get {
            return objc_getAssociatedObject(self, &UIViewController.isDetailViewControllerKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &UIViewController.isDetailViewControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension BarManagingSplitViewController: UISplitViewControllerDelegate {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { context in
        }, completion: { context in
            if self.isPlaceholderViewControllerLoaded && self.viewControllers.last == self.placeholderViewController {
                DispatchQueue.main.async {
                    self.showMasterViewController()
                }
            }
        })
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        vc.isDetailViewController = true
        
        if splitViewController.isCollapsed {
            splitViewController.viewControllers[0].show(vc, sender: sender)
            return true
        }
        
        if let sender = sender as? UIResponder, splitViewController.viewControllers.count >= 2, let detailViewController = splitViewController.viewControllers[1] as? BarManagingNavigationController {
            if sequence(first: sender, next: { $0.next }).first(where: { $0 === detailViewController }) != nil {
                detailViewController.show(vc, sender: sender)
                return true
            }
        }
        
        vc.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        vc.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.viewControllers = [splitViewController.viewControllers[0], BarManagingNavigationController(rootViewController: vc)]
        return true
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        return masterViewController
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return masterViewController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let primaryViewController = primaryViewController as? UINavigationController, let index = primaryViewController.viewControllers.index(where: { $0.isDetailViewController }) {
            let viewControllers = Array(primaryViewController.viewControllers[index..<primaryViewController.viewControllers.endIndex])
            viewControllers.first?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            viewControllers.first?.navigationItem.leftItemsSupplementBackButton = true
            primaryViewController.popToViewController(primaryViewController.viewControllers[index - 1], animated: false)
            let navigationController = BarManagingNavigationController(rootViewController: nil)
            navigationController.viewControllers = viewControllers
            return navigationController
        }
        
        return placeholderViewController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let primaryViewController = primaryViewController as? UINavigationController, secondaryViewController != loadedPlaceholderViewController, let secondaryViewController = secondaryViewController as? UINavigationController {
            let viewControllers = secondaryViewController.viewControllers
            secondaryViewController.viewControllers = []
            primaryViewController.viewControllers += viewControllers
        }
        
        return true
    }
}
