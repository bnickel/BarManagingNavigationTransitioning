//
//  ViewController.swift
//  BarManagingNavigationTransitioning
//
//  Created by Brian Nickel on 6/12/17.
//  Copyright © 2017 Brian Nickel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var popButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        if self == navigationController?.viewControllers.first {
            popButton.isHidden = true
            title = "Home"
        }
    }
    
    @IBAction func toggleNavigation(_ sender: Any) {
        setHidesNavigationBar(!hidesNavigationBar, animated: true)
    }

    @IBAction func pop(_ sender: Any) {
        guard let navigationController = navigationController else { return }
        if navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            print("Already at root.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHidden" {
            segue.destination.hidesNavigationBar = true
        }
        segue.destination.title = segue.identifier
    }
}

