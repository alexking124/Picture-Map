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
        
        NotificationCenter.default.addObserver(self, selector: #selector(upgradeCompleted), name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: nil)
        
        self.updateUsage()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        doneButton.tintColor = UIColor.darkGray
        self.navigationItem.leftBarButtonItem = doneButton
        
        self.iapHelper = IAPHelper(productIds: ["com.aking.PictureMap.unlock20"])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.authStateListenerToken = FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.updateViewForLoggedIn()
            } else {
                self.updateViewForLoggedOut()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        FIRAuth.auth()?.removeStateDidChangeListener(self.authStateListenerToken!)
    }
    
    func donePressed() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func updateViewForLoggedIn() {
        if let currentUser = FIRAuth.auth()?.currentUser {
            self.nameLabel.text = currentUser.email
            if let photoURL = currentUser.photoURL {
                self.profilePictureImageView.downloadImageFrom(link: photoURL.absoluteString)
            }
            self.authenticationButton.setTitle("Log Out", for: .normal)
            self.authenticationButton.tintColor = UIColor.red
        }
    }
    
    func updateViewForLoggedOut() {
        self.nameLabel.text = ""
        self.profilePictureImageView.image = UIImage(named: "account_circle")
        self.authenticationButton.setTitle("Log In", for: .normal)
        self.authenticationButton.tintColor = UIButton().tintColor
        
        self.presentingViewController?.dismiss(animated: true, completion:nil)
    }
    
    private func updateUsage() {
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            return;
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let usageReference = databaseReference.child("limit").child(currentUser.uid)
        usageReference.observe(.value, with: { (snapshot) in
            guard snapshot.exists() else {
                self.photosRemainingLabel.text = "-"
                return
            }
            guard let value = snapshot.value else {
                self.photosRemainingLabel.text = "-"
                return
            }
            self.photosRemainingLabel.text = String((value as AnyObject).integerValue!)
        })
    }
    
    @IBAction func upgradeAction(_ sender: AnyObject) {
        guard let iapHelper = self.iapHelper else {
            return
        }
        iapHelper.requestProducts(completionHandler: { (success, products) in
            if success == true {
                for product in products! {
                    if product.productIdentifier == "com.aking.PictureMap.unlock20" {
                        iapHelper.buyProduct(product)
                    }
                }
            }
        })
    }
    
    @objc private func upgradeCompleted(_ sender: NSNotification) {
        guard let identifier = sender.object else {
            return
        }
        if ((identifier as AnyObject).isEqual("com.aking.PictureMap.unlock20")) {
            let currentUser = FIRAuth.auth()?.currentUser
            
            guard let userID = currentUser?.uid else {
                return
            }
            let databaseReference = FIRDatabase.database().reference()
            let usageReference = databaseReference.child("limit").child(userID)
            usageReference.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let value = snapshot.value else {
                    return
                }
                usageReference.setValue((value as AnyObject).integerValue + 20)
            })
        }
    }
    
    @IBAction func authenticationButtonTapped(_ sender: AnyObject) {
        if UserProfile.currentUser() != nil {
            UserProfile.logOut()
        }
    }
    
}
