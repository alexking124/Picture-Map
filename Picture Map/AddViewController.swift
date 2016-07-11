//
//  AddViewController.swift
//  Picture Map
//
//  Created by Alex King on 7/11/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit
import GoogleMaps

class AddViewController: UIViewController {
    
    @IBOutlet weak var previewMapView: GMSMapView!
    @IBOutlet weak var markerImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 3)
        previewMapView.camera = camera
        previewMapView.bringSubviewToFront(markerImageView)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(backPressed))
    }
    
    func backPressed() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
