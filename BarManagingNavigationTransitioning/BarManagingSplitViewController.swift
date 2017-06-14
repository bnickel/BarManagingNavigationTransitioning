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
                if let detailViewController = masterViewController?.detailViewController(for: self) {
                    detailViewController.navigationItem.leftBarButtonItem = displayModeButtonItem
                    detailViewController.navigationItem.leftItemsSupplementBackButton = true
                    detailViewController.isDetailViewController = true
                    viewControllers.append(BarManagingNavigationController(rootViewController: detailViewController))
                } else {
                    viewControllers.append(placeholderViewController)
                }
            }
        }
    }
    
    fileprivate var loadedPlaceholderViewController: UIViewController?
    fileprivate weak var recentlyAddedDetailViewController: UIViewController?
    
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
    
    @objc(SEUI_masterViewControllerIsHidden) var masterViewControllerIsHidden: Bool {
        guard let masterViewController = masterViewController, masterViewController.isViewLoaded else { return true }
        return masterViewController.view.window == nil || !masterViewController.view.frame.intersects(view.frame)
    }
    
    @objc(SEUI_showMasterViewController) func showMasterViewController() {
        guard masterViewControllerIsHidden else { return }
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
            self.expandIfNeeded()
        })
    }
    
    private func expandIfNeeded() {
        if
            viewControllers.last == loadedPlaceholderViewController ||
            (recentlyAddedDetailViewController != nil && (viewControllers.last as? UINavigationController)?.topViewController == recentlyAddedDetailViewController) {
            DispatchQueue.main.async {
                self.showMasterViewController()
            }
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        vc.isDetailViewController = true
        
        if splitViewController.isCollapsed {
            masterViewController?.targetNavigationController(for: self)?.show(vc, sender: sender)
            return true
        }
        
        if let sender = sender as? UIResponder, splitViewController.viewControllers.count >= 2, splitViewController.viewControllers.last != loadedPlaceholderViewController, let detailViewController = splitViewController.viewControllers[1] as? BarManagingNavigationController {
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
        
        let viewControllers = primaryViewController.removeDetailViewControllers(for: splitViewController)
        
        if viewControllers.count > 0 {
            let navigationController = BarManagingNavigationController(rootViewController: nil)
            navigationController.viewControllers = viewControllers
            return navigationController
        } else if let detailViewController = masterViewController?.detailViewController(for: self) {
            detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            detailViewController.navigationItem.leftItemsSupplementBackButton = true
            detailViewController.isDetailViewController = true
            recentlyAddedDetailViewController = detailViewController
            return BarManagingNavigationController(rootViewController: detailViewController)
        } else {
            return placeholderViewController
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if secondaryViewController != loadedPlaceholderViewController, let primaryViewController = primaryViewController.targetNavigationController(for: splitViewController), let secondaryViewController = secondaryViewController as? UINavigationController {
            let viewControllers = secondaryViewController.viewControllers
            if viewControllers.first?.navigationItem.leftBarButtonItem == splitViewController.displayModeButtonItem {
                viewControllers.first?.navigationItem.leftBarButtonItem = nil
            }
            secondaryViewController.viewControllers = []
            primaryViewController.viewControllers += viewControllers
        }
        
        return true
    }
}

extension UIViewController {
    
    @objc(SEUI_targetNavigationControllerForSplitViewController:) func targetNavigationController(for splitViewController: UISplitViewController) -> UINavigationController? {
        return nil
    }
    
    @objc(SEUI_removeDetailViewControllersForSplitViewController:) func removeDetailViewControllers(for splitViewController: UISplitViewController) -> [UIViewController] {
        return []
    }
    
    @objc(SEUI_detailViewControllerForSplitViewController:) func detailViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        return nil
    }
}

extension UINavigationController {
    
    override func targetNavigationController(for splitViewController: UISplitViewController) -> UINavigationController? {
        return self
    }
    
    override func removeDetailViewControllers(for splitViewController: UISplitViewController) -> [UIViewController] {
        guard let index = self.viewControllers.index(where: { $0.isDetailViewController }) else { return [] }
        let viewControllers = Array(self.viewControllers[index..<self.viewControllers.endIndex])
        viewControllers.first?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        viewControllers.first?.navigationItem.leftItemsSupplementBackButton = true
        popToViewController(self.viewControllers[index - 1], animated: false)
        return viewControllers
    }
    
    override func detailViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        return viewControllers.last?.detailViewController(for: splitViewController)
    }
}

extension UITabBarController {
    
    override func targetNavigationController(for splitViewController: UISplitViewController) -> UINavigationController? {
        return selectedViewController?.targetNavigationController(for: splitViewController)
    }
    
    override func removeDetailViewControllers(for splitViewController: UISplitViewController) -> [UIViewController] {
        guard let viewControllers = viewControllers else { return [] }
        
        for viewController in viewControllers where viewController != selectedViewController {
            _ = viewController.removeDetailViewControllers(for: splitViewController)
        }
        
        return selectedViewController?.removeDetailViewControllers(for: splitViewController) ?? []
    }
    
    override func detailViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        return selectedViewController?.detailViewController(for: splitViewController)
    }
}
