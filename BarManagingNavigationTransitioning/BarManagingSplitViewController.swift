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
        return splitViewController.viewControllers.first
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return splitViewController.viewControllers.first
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
        
        return DummyViewController()
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let primaryViewController = primaryViewController as? UINavigationController, let secondaryViewController = secondaryViewController as? UINavigationController {
            let viewControllers = secondaryViewController.viewControllers.filter({ !($0 is DummyViewController) })
            secondaryViewController.viewControllers = []
            primaryViewController.viewControllers += viewControllers
        }
        
        return true
    }
}

private class DummyViewController: UIViewController {
}
