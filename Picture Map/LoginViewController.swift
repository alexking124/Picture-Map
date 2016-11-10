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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 2)
        self.mapView.camera = camera
    }
}

extension LoginViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func signIn(signIn: GIDSignIn!, didSignInForUser googleUser: GIDGoogleUser!, withError error: NSError?) {
        if let googleUser = googleUser {
            let authentication = googleUser.authentication
            let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                if error != nil {
                    return
                }
                
                let updateProperty = user?.profileChangeRequest()
                updateProperty?.photoURL = googleUser.profile.imageURLWithDimension(100)
                updateProperty?.commitChangesWithCompletion(nil)
                
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
}
