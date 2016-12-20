//
//  ProgressViewController.swift
//  Picture Map
//
//  Created by Tigger on 7/12/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

class ProgressViewController: UIViewController {
    
    @IBOutlet weak var indicatorBackgroundView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var showsProgressIndicator: Bool!
    
    convenience init() {
        self.init(nibName: "ProgressViewController", bundle: nil)
        showsProgressIndicator = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressView.progress = 0.0
        self.indicatorBackgroundView.layer.cornerRadius = 7
    }
    
    func updateProgress(progress: Progress) {
        self.progressView.progress = Float(progress.fractionCompleted)
    }
}
