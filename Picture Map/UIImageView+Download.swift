//
//  UIImage+Download.swift
//  Picture Map
//
//  Created by Alex King on 7/11/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func downloadImageFrom(link: String, completion: @escaping ((Void) -> Void) = {}) {
        guard let url = NSURL(string: link) else { return }
        URLSession.shared.dataTask(with: url as URL) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async {
                self.image = image
                completion()
            }
        }.resume()
    }
}
