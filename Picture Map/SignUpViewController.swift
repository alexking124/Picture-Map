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
    @IBOutlet weak var emailImageView: UIImageView!
    @IBOutlet weak var passwordImageView: UIImageView!
    @IBOutlet weak var confirmPasswordImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.signUpButton.isEnabled = false
        
        let imageTint = UIColor.darkGray
        emailImageView.tintColor = imageTint
        passwordImageView.tintColor = imageTint
        confirmPasswordImageView.tintColor = imageTint
    }
    
    @IBAction func textFieldChanged(_ sender: AnyObject) {
        if (emailTextField.text!.isEmpty || passwordTextField.text!.isEmpty || confirmPasswordTextField.text!.isEmpty) {
            self.signUpButton.isEnabled = false
        } else {
            if (passwordTextField.text! == confirmPasswordTextField.text) {
                self.signUpButton.isEnabled = true
            }
            
        }
    }
    
    @IBAction func signUpButtonAction(_ sender: AnyObject) {
        FIRAuth.auth()?.createUser(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
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

    @IBAction func backButtonAction(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }

}

extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField === passwordTextField {
            confirmPasswordImageView.becomeFirstResponder()
        } else if textField === confirmPasswordTextField {
            confirmPasswordTextField.resignFirstResponder()
            self.signUpButtonAction(signUpButton)
        }
        
        return true
    }
    
}
