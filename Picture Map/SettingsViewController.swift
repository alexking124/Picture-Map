//
//  SettingsViewController.swift
//  Picture Map
//
//  Created by Tigger on 7/20/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import Firebase
import FirebaseAuth
import GoogleSignIn

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photosRemainingLabel: UILabel!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var authenticationButton: UIButton!
    
    var iapHelper: IAPHelper?
    var authStateListenerToken: FIRAuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        self.profilePictureImageView.layer.cornerRadius = self.profilePictureImageView.frame.width/2
        self.profilePictureImageView.clipsToBounds = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(upgradeCompleted), name: IAPHelper.IAPHelperPurchaseNotification, object: nil)
        
        self.updateUsage()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(donePressed))
        doneButton.tintColor = UIColor.darkGrayColor()
        self.navigationItem.leftBarButtonItem = doneButton
        
        self.iapHelper = IAPHelper(productIds: ["com.aking.PictureMap.unlock20"])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.authStateListenerToken = FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.updateViewForLoggedIn()
            } else {
                self.updateViewForLoggedOut()
            }
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        FIRAuth.auth()?.removeAuthStateDidChangeListener(self.authStateListenerToken!)
    }
    
    func donePressed() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateViewForLoggedIn() {
        if let currentUser = FIRAuth.auth()?.currentUser {
            self.nameLabel.text = currentUser.email
            if let photoURL = currentUser.photoURL {
                self.profilePictureImageView.downloadImageFrom(photoURL.absoluteString!)
            }
            self.authenticationButton.setTitle("Log Out", forState: .Normal)
            self.authenticationButton.tintColor = UIColor.redColor()
        }
    }
    
    func updateViewForLoggedOut() {
        self.nameLabel.text = ""
        self.profilePictureImageView.image = UIImage(named: "account_circle")
        self.authenticationButton.setTitle("Log In", forState: .Normal)
        self.authenticationButton.tintColor = UIButton().tintColor
        
        self.presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }
    
    private func updateUsage() {
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            return;
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let usageReference = databaseReference.child("limit").child(currentUser.uid)
        usageReference.observeEventType(.Value, withBlock: { (snapshot) in
            guard snapshot.exists() else {
                self.photosRemainingLabel.text = "-"
                return
            }
            guard let value = snapshot.value else {
                self.photosRemainingLabel.text = "-"
                return
            }
            self.photosRemainingLabel.text = String(value.integerValue!)
        })
    }
    
    @IBAction func upgradeAction(sender: AnyObject) {
        guard let iapHelper = self.iapHelper else {
            return
        }
        iapHelper.requestProducts({ (success, products) in
            if success == true {
                for product in products! {
                    if product.productIdentifier == "com.aking.PictureMap.unlock20" {
                        iapHelper.buyProduct(product)
                    }
                }
            }
        })
    }
    
    @objc private func upgradeCompleted(sender: NSNotification) {
        guard let identifier = sender.object else {
            return
        }
        if (identifier.isEqualToString("com.aking.PictureMap.unlock20")) {
            let currentUser = FIRAuth.auth()?.currentUser
            
            guard let userID = currentUser?.uid else {
                return
            }
            let databaseReference = FIRDatabase.database().reference()
            let usageReference = databaseReference.child("limit").child(userID)
            usageReference.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                guard let value = snapshot.value else {
                    return
                }
                usageReference.setValue(value.integerValue + 20)
            })
        }
    }
    
    @IBAction func authenticationButtonTapped(sender: AnyObject) {
        if UserProfile.currentUser() != nil {
            UserProfile.logOut()
        } else {
            UserProfile.logInWithSignInDelegate(self, uiDelegate: self)
        }
    }
    
}

extension SettingsViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func signIn(signIn: GIDSignIn!, didSignInForUser googleUser: GIDGoogleUser!, withError error: NSError?) {
        if let googleUser = googleUser {
            let authentication = googleUser.authentication
            let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                if error != nil {
                    return
                }
                
                let updateProperty = user?.profileChangeRequest()
                updateProperty?.photoURL = googleUser.profile.imageURLWithDimension(60)
                updateProperty?.commitChangesWithCompletion(nil)
            }
        }
    }
    
}
