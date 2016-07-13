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

class AddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var previewMapView: GMSMapView!
    @IBOutlet weak var markerImageView: UIImageView!
    @IBOutlet weak var imagePreview: UIImageView!
    
    var doneButton: UIBarButtonItem?
    var imageAsset: PHAsset?
    
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
        if let asset = imageAsset {
            let currentUser = FIRAuth.auth()?.currentUser
            
            asset.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, info) in
                guard let imageURL = contentEditingInput?.fullSizeImageURL else {
                    return
                }
                guard let userID = currentUser?.uid else {
                    return
                }
                let remoteFilePath = String(format: "%@/%@", userID, NSUUID().UUIDString)
                
                let storageReference = FIRStorage.storage().reference()
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let progressViewController = ProgressViewController()
                self.view.fillWithView(progressViewController.view)
                let uploadTask = storageReference.child(remoteFilePath).putFile(imageURL, metadata: metadata, completion: { (storageMetadata, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        let currentLocation = self.previewMapView.camera.target
                        let testData = ["latitude": currentLocation.latitude,
                                        "longitude": currentLocation.longitude,
                                        "imagePath": storageMetadata?.downloadURL()?.absoluteString as! AnyObject,
                                        "title": "",
                                        "description": ""]
                        let databaseReference = FIRDatabase.database().reference()
                        let test = databaseReference.child("pics").child((currentUser?.uid)!).childByAutoId()
                        test.setValue(testData)
                    }
                    
                    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                })
                uploadTask.observeStatus(.Progress, handler: { (snapshot) in
                    guard let progress = snapshot.progress else {
                        return
                    }
                    progressViewController.updateProgress(progress)
                })
            })
        }
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
        
        let asset = PHAsset.fetchAssetsWithALAssetURLs([info[UIImagePickerControllerReferenceURL] as! NSURL], options: nil).lastObject as! PHAsset
        imageAsset = asset
        if let location = asset.location {
            previewMapView.moveCamera(GMSCameraUpdate.setTarget(location.coordinate, zoom: 8.0))
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
