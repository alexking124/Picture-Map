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
    @IBOutlet weak var changeLocationButton: UIButton!
    
    var doneButton: UIBarButtonItem?
    var photoDate: Date = Date.distantPast
    var assetLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.camera(withLatitude: 37.0902, longitude: -95.7129, zoom: 2)
        self.previewMapView.camera = camera
        self.previewMapView.bringSubview(toFront: self.markerImageView)
        self.previewMapView.bringSubview(toFront: self.overlayView)
        self.previewMapView.bringSubview(toFront: changeLocationButton)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backPressed))
        self.doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePressed))
        self.doneButton?.isEnabled = false
        self.changeLocationButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = self.doneButton
        
        self.descriptionTextView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    @IBAction func changeLocationButtonPressed(_ sender: Any) {
        let pickerViewController = LocationPickerViewController(assetLocation)
        pickerViewController.delegate  = self
        self.present(pickerViewController, animated: true, completion: nil);
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(AddViewController.keyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (userInfo.object(forKey: UIKeyboardFrameBeginUserInfoKey)! as AnyObject).cgRectValue.size
        let contentInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var viewRect = view.frame
        viewRect.size.height -= keyboardSize.height
        if viewRect.contains(self.descriptionTextView.frame.origin) {
            self.scrollView.scrollRectToVisible(viewRect, animated: true)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.scrollView.contentSize = self.contentView.frame.size
    }
    
    func backPressed() {
        self.view.endEditing(true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func donePressed() {
        self.view.endEditing(true)
        let currentUser = FIRAuth.auth()?.currentUser
        
        guard let userID = currentUser?.uid else {
            fatalError("Couldn't get the current user!")
        }
        let remoteFilePath = String(format: "%@/%@", userID, NSUUID().uuidString)
        
        let storageReference = FIRStorage.storage().reference()
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let progressViewController = ProgressViewController()
        self.navigationController!.view.fillWithView(view: progressViewController.view)
        let uploadTask = storageReference.child(remoteFilePath).put(UIImageJPEGRepresentation(self.imagePreview.image!, 0.1)!, metadata: metadata, completion: { (storageMetadata, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                let currentLocation = self.previewMapView.camera.target
                let pinMetadata = ["latitude": currentLocation.latitude,
                                "longitude": currentLocation.longitude,
                                "imagePath": storageMetadata?.downloadURL()?.absoluteString as AnyObject,
                                "title": self.titleLabel.text as AnyObject,
                                "description": self.descriptionTextView.text,
                                "date": NSNumber.init(value: self.photoDate.timeIntervalSinceReferenceDate)] as [String : Any]
                
                let pinReference = DatabaseInterface.shared.insertNewPin()
                DatabaseInterface.shared.updatePin(pinReference.key, metadata: pinMetadata)
            }
            
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        })
        uploadTask.observe(.progress, handler: { (snapshot) in
            guard let progress = snapshot.progress else {
                return
            }
            progressViewController.updateProgress(progress: progress)
        })
    }
    
    @IBAction func pickImage(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
}

extension AddViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePreview.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        self.dismiss(animated: true, completion: nil)
        self.pickImageButton.isHidden = true
        self.changeLocationButton.isEnabled = true
        
        let asset = PHAsset.fetchAssets(withALAssetURLs: [(info[UIImagePickerControllerReferenceURL] as! NSURL) as URL], options: nil).firstObject
        if let location = asset!.location {
            self.doneButton?.isEnabled = true
            assetLocation = location.coordinate
            self.previewMapView.moveCamera(GMSCameraUpdate.setTarget(location.coordinate, zoom: 8.0))
        }
        if let date = asset!.creationDate {
            photoDate = date
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension AddViewController: LocationPickerDelegate {
    func didFinishPickingLocation(location: CLLocationCoordinate2D) {
        self.dismiss(animated: true, completion: nil)
        previewMapView.moveCamera(GMSCameraUpdate.setTarget(location, zoom: 8))
        self.doneButton?.isEnabled = true
    }
}

extension AddViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
            self.descriptionPlaceholder.isHidden = false
        } else {
            self.descriptionPlaceholder.isHidden = true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
}

extension AddViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleLabel {
            self.descriptionTextView.becomeFirstResponder()
        }
        return false
    }
    
}
