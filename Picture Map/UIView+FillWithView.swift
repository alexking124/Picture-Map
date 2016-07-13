//
//  UIView+FillWithView.swift
//  Picture Map
//
//  Created by Tigger on 7/12/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

extension UIView {
    func fillWithView(view: UIView) {
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(topConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        self.addConstraint(bottomConstraint)
        
        let leftConstraint = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0.0)
        self.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0.0)
        self.addConstraint(rightConstraint)
    }
}
