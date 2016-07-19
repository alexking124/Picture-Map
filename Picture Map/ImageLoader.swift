//
//  ImageLoader.swift
//  Picture Map
//
//  Created by Tigger on 7/18/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit

import FirebaseAuth

class ImageLoader: AnyObject {
    
    static let sharedLoader = ImageLoader()
    let imageCache: NSCache = NSCache()
    
    class func currentUserCacheDirectoryPath() -> String? {
        guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
            return nil
        }
        let userDirectory = cacheDirectory.stringByAppendingString("/\(FIRAuth.auth()?.currentUser?.uid)")
        var isDirectory: ObjCBool = false
        if !NSFileManager.defaultManager().fileExistsAtPath(userDirectory, isDirectory: &isDirectory) && !isDirectory {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(userDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Couldn't create user's cache directory: %@", error)
                return nil
            }
        }
        return userDirectory
    }
    
    func imageForPin(pin: Pin, completion:(image: UIImage) -> Void) {
        guard let cachedImage = self.cachedImageForPin(pin) else {
            guard let localImage = self.localImageForPin(pin) else {
                self.fetchRemoteImageForPin(pin, completion:{ image in
                    completion(image: image!)
                })
                return
            }
            completion(image: localImage)
            return
        }
        completion(image: cachedImage)
}
    
    func cachedImageForPin(pin: Pin) -> UIImage? {
        let image = self.imageCache.objectForKey(pin.identifier) as? UIImage
        return image
    }
    
    func localImageForPin(pin: Pin) -> UIImage? {
        guard let pinLocation = ImageLoader.currentUserCacheDirectoryPath()?.stringByAppendingString("/\(pin.identifier)") else {
            return nil
        }
        guard let imageData = NSFileManager.defaultManager().contentsAtPath(pinLocation) else {
            return nil
        }
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        self.imageCache.setObject(image, forKey: pin.identifier)
        return image
    }
    
    func fetchRemoteImageForPin(pin: Pin, completion:(image: UIImage?) -> Void) {
        guard let url = NSURL(string: pin.imagePath) else { return }
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            guard
                let httpURLResponse = response as? NSHTTPURLResponse where httpURLResponse.statusCode == 200,
                let mimeType = response?.MIMEType where mimeType.hasPrefix("image"),
                let data = data where error == nil,
                let image = UIImage(data: data)
                else {
                    completion(image: nil)
                    return
                }
            self.imageCache.setObject(image, forKey: pin.identifier)
            if let pinLocation = ImageLoader.currentUserCacheDirectoryPath()?.stringByAppendingString("/\(pin.identifier)") {
                NSFileManager.defaultManager().createFileAtPath(pinLocation, contents: data, attributes: nil)
            }
            dispatch_async(dispatch_get_main_queue(), {
                completion(image: image)
            })
        }.resume()
    }
}
