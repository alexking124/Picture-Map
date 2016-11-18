//
//  LoginViewController.swift
//  Picture Map
//
//  Created by Alex King on 11/16/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.logInButton.enabled = false
        self.navigationController?.navigationBarHidden = true
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func textFieldChanged(sender: AnyObject) {
        if (self.emailTextField.text!.isEmpty || self.passwordTextField.text!.isEmpty) {
            self.logInButton.enabled = false
        } else {
            self.logInButton.enabled = true
        }
    }

    @IBAction func logInButtonPressed(sender: AnyObject) {
        FIRAuth.auth()?.signInWithEmail(self.emailTextField.text!, password: self.passwordTextField.text!, completion: { (user, error) in
//            print("User: \(user), error: \(error)")
            if (error != nil) {
                print("Error logging in: \(error)")
                let errorAlert = UIAlertController(title: "Error logging in", message: error?.localizedDescription, preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                errorAlert.addAction(defaultAction)
                self.presentViewController(errorAlert, animated: true, completion: nil)
            } else {
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
    
    @IBAction func signUpButtonPressed(sender: AnyObject) {
        self.navigationController?.pushViewController(SignUpViewController(), animated: true)
    }
    
}

