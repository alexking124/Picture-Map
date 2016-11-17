//
//  LoginViewController.swift
//  Picture Map
//
//  Created by Alex King on 11/9/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import GoogleMaps
import GoogleSignIn
import Firebase
import FirebaseAuthUI

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var logInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logInButton.layer.cornerRadius = 4
        
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 2)
        self.mapView.camera = camera
    }
    
    @IBAction func logInButtonPressed(sender: AnyObject) {
        let navigationController = UINavigationController(rootViewController: LoginViewController())
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
}
