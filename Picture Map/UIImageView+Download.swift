//
//  UIImage+Download.swift
//  Picture Map
//
//  Created by Alex King on 7/11/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func downloadImageFrom(link: String, completion: ((Void) -> Void) = {}) {
        guard let url = NSURL(string: link) else { return }
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            guard
                let httpURLResponse = response as? NSHTTPURLResponse where httpURLResponse.statusCode == 200,
                let mimeType = response?.MIMEType where mimeType.hasPrefix("image"),
                let data = data where error == nil,
                let image = UIImage(data: data)
                else { return }
            dispatch_async(dispatch_get_main_queue(), {
                self.image = image
                completion()
            })
            }.resume()
    }
}