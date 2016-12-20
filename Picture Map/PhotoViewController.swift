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
    @IBOutlet weak var dateLabel: UILabel!
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
        
        ImageLoader.sharedLoader.imageForPin(pin: self.pin, completion: { (image) in
//            self.imageView.image = image
            self.secondaryImageView.image = image
//            self.updateScrollViewForNewImage()
            self.loadingIndicator.stopAnimating()
        })
        
        if self.pin.title.isEmpty && self.pin.description.isEmpty {
            self.bottomContentView.isHidden = true
        } else {
            self.titleLabel.text = self.pin.title
            self.descriptionLabel.text = self.pin.description
        }
        
        if self.pin.dateTaken as Date != NSDate.distantPast {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.medium
            self.dateLabel.text = dateFormatter.string(from: self.pin.dateTaken as Date)
        } else {
            self.dateLabel.isHidden = true
        }
        
        self.doubleTapRecognizer.isEnabled = false
        self.singleTapRecognizer.require(toFail: self.doubleTapRecognizer)
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
    
    @IBAction func backPressed(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editButtonPressed(_ sender: AnyObject) {
        let editAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        editAlert.addAction(cancelAction)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
            
        }
        editAlert.addAction(editAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .default) { (action) in
            self.deleteButtonPressed()
        }
        editAlert.addAction(deleteAction)
        
        self.present(editAlert, animated: true, completion: nil)
    }
    
    func deleteButtonPressed() {
        let deleteAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this photo?", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            //Delete image
            self.deleteCurrentImage()
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        deleteAlert.addAction(cancelAction)
        deleteAlert.addAction(confirmAction)
        self.present(deleteAlert, animated: true, completion: nil)
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
        usageReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let value = snapshot.value else {
                return
            }
            usageReference.setValue((value as AnyObject).integerValue + 1)
        })
        
        let storageReference = FIRStorage.storage().reference()
        let downloadURL = self.pin.imagePath
        let identifier = downloadURL.components(separatedBy: "%2F")[1].components(separatedBy: "?")[0]
        let remotePath = String(format: "%@/%@", userID, identifier)
        storageReference.child(remotePath).delete { (error) in
            if (error != nil) {
                print("Error deleting photo from storage: \(error)")
            }
            
        }
    }
    
    @IBAction func doubleTappedImage(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.3) {
            if self.scrollView.zoomScale != self.minimumZoomScale {
                self.scrollView.zoomScale = self.minimumZoomScale
            } else {
                self.scrollView.zoomScale = self.maximumZoomScale
            }
        }
    }
    
    @IBAction func singleTappedImage(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.3) {
            self.bottomContentView.alpha = 1.0 - self.bottomContentView.alpha
            self.backButton.alpha = 1.0 - self.backButton.alpha
            self.editButton.alpha = 1.0 - self.editButton.alpha
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
}
