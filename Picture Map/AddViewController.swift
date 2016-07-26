//
//  AddViewController.swift
//  Picture Map
//
//  Created by Alex King on 7/11/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit
import Photos

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import GoogleMaps
import GoogleSignIn

class AddViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var pickImageButton: UIButton!
    @IBOutlet weak var previewMapView: GMSMapView!
    @IBOutlet weak var markerImageView: UIImageView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var descriptionPlaceholder: UILabel!
    
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 3)
        self.previewMapView.camera = camera
        self.previewMapView.bringSubviewToFront(self.markerImageView)
        self.previewMapView.bringSubviewToFront(self.overlayView)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(backPressed))
        self.doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(donePressed))
        self.doneButton?.enabled = false
        self.navigationItem.rightBarButtonItem = self.doneButton
        
        self.descriptionTextView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    func registerKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo!
        let keyboardSize = userInfo.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        let contentInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var viewRect = view.frame
        viewRect.size.height -= keyboardSize.height
        if CGRectContainsPoint(viewRect, self.descriptionTextView.frame.origin) {
            self.scrollView.scrollRectToVisible(viewRect, animated: true)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset = UIEdgeInsetsZero
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.scrollView.contentSize = self.contentView.frame.size
    }
    
    func backPressed() {
        self.view.endEditing(true)
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func donePressed() {
        self.view.endEditing(true)
        let currentUser = FIRAuth.auth()?.currentUser
        
        guard let userID = currentUser?.uid else {
            return
        }
        let remoteFilePath = String(format: "%@/%@", userID, NSUUID().UUIDString)
        
        let storageReference = FIRStorage.storage().reference()
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let progressViewController = ProgressViewController()
        self.navigationController!.view.fillWithView(progressViewController.view)
        let uploadTask = storageReference.child(remoteFilePath).putData(UIImageJPEGRepresentation(self.imagePreview.image!, 0.1)!, metadata: metadata, completion: { (storageMetadata, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                let currentLocation = self.previewMapView.camera.target
                let pinMetadata = ["latitude": currentLocation.latitude,
                                "longitude": currentLocation.longitude,
                                "imagePath": storageMetadata?.downloadURL()?.absoluteString as! AnyObject,
                                "title": self.titleLabel.text as! AnyObject,
                                "description": self.descriptionTextView.text]
                let databaseReference = FIRDatabase.database().reference()
                let test = databaseReference.child("pins").child(userID).childByAutoId()
                test.setValue(pinMetadata)
            }
            
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        })
        uploadTask.observeStatus(.Progress, handler: { (snapshot) in
            guard let progress = snapshot.progress else {
                return
            }
            progressViewController.updateProgress(progress)
        })
    }
    
    @IBAction func pickImage(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
}

extension AddViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePreview.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        self.dismissViewControllerAnimated(true, completion: nil)
        self.doneButton?.enabled = true
        self.pickImageButton.hidden = true
        self.overlayView.hidden = true
        
        let asset = PHAsset.fetchAssetsWithALAssetURLs([info[UIImagePickerControllerReferenceURL] as! NSURL], options: nil).firstObject as! PHAsset
        if let location = asset.location {
            self.previewMapView.moveCamera(GMSCameraUpdate.setTarget(location.coordinate, zoom: 8.0))
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension AddViewController: UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        if textView.text == "" {
            self.descriptionPlaceholder.hidden = false
        } else {
            self.descriptionPlaceholder.hidden = true
        }
    }
    
}
