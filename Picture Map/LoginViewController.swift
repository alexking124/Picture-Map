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
    @IBOutlet weak var emailImageView: UIImageView!
    @IBOutlet weak var passwordImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.logInButton.isEnabled = false
        self.navigationController?.isNavigationBarHidden = true
        self.emailImageView.tintColor = UIColor.darkGray
        self.passwordImageView.tintColor = UIColor.darkGray
    }
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func textFieldChanged(_ sender: AnyObject) {
        if (self.emailTextField.text!.isEmpty || self.passwordTextField.text!.isEmpty) {
            self.logInButton.isEnabled = false
        } else {
            self.logInButton.isEnabled = true
        }
    }

    @IBAction func logInButtonPressed(_ sender: AnyObject) {
        FIRAuth.auth()?.signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!, completion: { (user, error) in
//            print("User: \(user), error: \(error)")
            if (error != nil) {
                print("Error logging in: \(error)")
                let errorAlert = UIAlertController(title: "Error logging in", message: error?.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                errorAlert.addAction(defaultAction)
                self.present(errorAlert, animated: true, completion: nil)
            } else {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func signUpButtonPressed(_ sender: AnyObject) {
        self.navigationController?.pushViewController(SignUpViewController(), animated: true)
    }
    
}

