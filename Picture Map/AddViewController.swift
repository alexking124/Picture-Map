//
//  AddViewController.swift
//  Picture Map
//
//  Created by Alex King on 7/11/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GoogleMaps
import GoogleSignIn

class AddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var previewMapView: GMSMapView!
    @IBOutlet weak var markerImageView: UIImageView!
    @IBOutlet weak var imagePreview: UIImageView!
    
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 3)
        previewMapView.camera = camera
        previewMapView.bringSubviewToFront(markerImageView)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(backPressed))
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(donePressed))
        doneButton?.enabled = false
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    func backPressed() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func donePressed() {
        let testData = ["email": GIDSignIn.sharedInstance().currentUser.profile.email, "data": "test"]
        let databaseReference = FIRDatabase.database().reference()
        let test = databaseReference.child("test").childByAutoId()
        test.setValue(testData)
        
        
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func pickImage(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self .presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePreview.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.dismissViewControllerAnimated(true, completion: nil)
        self.doneButton?.enabled = true
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
