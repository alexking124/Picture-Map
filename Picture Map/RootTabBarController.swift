//
//  RootTabBarController.swift
//  Picture Map
//
//  Created by Alex King on 11/17/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import FirebaseAuth

class RootTabBarController: UITabBarController {
    
    var authStateListenerToken: FIRAuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.hidden = true
        
        self.viewControllers = [MapViewController(), WelcomeViewController()]

        // Do any additional setup after loading the view.
        
        self.authStateListenerToken = FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.selectedIndex = 0
            } else {
                self.selectedIndex = 1
            }
        })
    }

    
}
