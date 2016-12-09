//
//  PhotoViewController.swift
//  Picture Map
//
//  Created by Tigger on 7/14/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var secondaryImageView: UIImageView!
    @IBOutlet weak var bottomContentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var doubleTapRecognizer: UITapGestureRecognizer!
    @IBOutlet var singleTapRecognizer: UITapGestureRecognizer!
    
    var pin: Pin
    var minimumZoomScale: CGFloat = 0.2
    var maximumZoomScale: CGFloat = 0.5
    
    init(pin: Pin) {
        self.pin = pin
        super.init(nibName: "PhotoViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        
        ImageLoader.sharedLoader.imageForPin(self.pin, completion: { (image) in
//            self.imageView.image = image
            self.secondaryImageView.image = image
//            self.updateScrollViewForNewImage()
            self.loadingIndicator.stopAnimating()
        })
        
        if self.pin.title.isEmpty && self.pin.description.isEmpty {
            self.bottomContentView.hidden = true
        } else {
            self.titleLabel.text = self.pin.title
            self.descriptionLabel.text = self.pin.description
        }
        
        self.doubleTapRecognizer.enabled = false
        self.singleTapRecognizer.requireGestureRecognizerToFail(self.doubleTapRecognizer)
    }
    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        self.updateScrollViewForNewImage()
//    }
    
    func updateScrollViewForNewImage() {
        guard let image = self.imageView.image else {
            return
        }
        
        self.scrollView.contentSize = image.size
        
        let screenAspectRatio = self.view.frame.size.width / self.view.frame.size.height
        let imageAspectRatio = image.size.width / image.size.height
        
        if screenAspectRatio < imageAspectRatio {
            // image is wider than screen, so fit the width
            self.minimumZoomScale = self.view.frame.size.width / image.size.width
            self.maximumZoomScale = self.minimumZoomScale * 2
        } else {
            // fit the height
            self.minimumZoomScale = self.view.frame.size.height / image.size.height
            self.maximumZoomScale = self.minimumZoomScale * 2
        }
        
        self.scrollView.maximumZoomScale = self.maximumZoomScale
        self.scrollView.minimumZoomScale = self.minimumZoomScale
        self.scrollView.zoomScale = self.minimumZoomScale
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        
    }
    
    func deleteButtonPressed(sender: AnyObject) {
        let deleteAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this photo?", preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
            //Delete image
            self.deleteCurrentImage()
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        deleteAlert.addAction(cancelAction)
        deleteAlert.addAction(confirmAction)
        self.presentViewController(deleteAlert, animated: true, completion: nil)
    }
    
    private func deleteCurrentImage() {
        let currentUser = FIRAuth.auth()?.currentUser
        guard let userID = currentUser?.uid else {
            return
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let pinReference = databaseReference.child("pins").child(userID).child(self.pin.identifier)
        pinReference.removeValue()
        
        let usageReference = databaseReference.child("limit").child(userID)
        usageReference.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            guard let value = snapshot.value else {
                return
            }
            usageReference.setValue(value.integerValue + 1)
        })
        
        let storageReference = FIRStorage.storage().reference()
        let downloadURL = self.pin.imagePath
        let identifier = downloadURL.componentsSeparatedByString("%2F")[1].componentsSeparatedByString("?")[0]
        let remotePath = String(format: "%@/%@", userID, identifier)
        storageReference.child(remotePath).deleteWithCompletion { (error) in
            if (error != nil) {
                print("Error deleting photo from storage: \(error)")
            }
            
        }
    }
    
    @IBAction func doubleTappedImage(sender: AnyObject) {
        UIView.animateWithDuration(0.3) {
            if self.scrollView.zoomScale != self.minimumZoomScale {
                self.scrollView.zoomScale = self.minimumZoomScale
            } else {
                self.scrollView.zoomScale = self.maximumZoomScale
            }
        }
    }
    
    @IBAction func singleTappedImage(sender: AnyObject) {
        UIView.animateWithDuration(0.3) {
            self.bottomContentView.alpha = 1.0 - self.bottomContentView.alpha
            self.backButton.alpha = 1.0 - self.backButton.alpha
            self.editButton.alpha = 1.0 - self.editButton.alpha
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
