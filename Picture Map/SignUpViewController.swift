//
//  SignUpViewController.swift
//  Picture Map
//
//  Created by Alex King on 11/17/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.signUpButton.enabled = false
    }
    
    @IBAction func textFieldChanged(sender: AnyObject) {
        if (emailTextField.text!.isEmpty || passwordTextField.text!.isEmpty || confirmPasswordTextField.text!.isEmpty) {
            self.signUpButton.enabled = false
        } else {
            if (passwordTextField.text! == confirmPasswordTextField.text) {
                self.signUpButton.enabled = true
            }
            
        }
    }
    
    @IBAction func signUpButtonAction(sender: AnyObject) {
        FIRAuth.auth()?.createUserWithEmail(emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
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

    @IBAction func backButtonAction(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }

}
