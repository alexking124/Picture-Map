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
    let imageCache: NSCache = NSCache<NSString, UIImage>()
    
    class func currentUserCacheDirectoryPath() -> String? {
        guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        let userDirectory = cacheDirectory + "/\(FIRAuth.auth()?.currentUser?.uid)"
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: userDirectory, isDirectory: &isDirectory) && !isDirectory.boolValue {
            do {
                try FileManager.default.createDirectory(atPath: userDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Couldn't create user's cache directory: %@", error)
                return nil
            }
        }
        return userDirectory
    }
    
    func imageForPin(pin: Pin, completion:@escaping (_ image: UIImage) -> Void) {
        guard let cachedImage = self.cachedImageForPin(pin: pin) else {
            guard let localImage = self.localImageForPin(pin: pin) else {
                self.fetchRemoteImageForPin(pin: pin, completion:{ image in
                    completion(image!)
                })
                return
            }
            completion(localImage)
            return
        }
        completion(cachedImage)
}
    
    private func cachedImageForPin(pin: Pin) -> UIImage? {
        let image = self.imageCache.object(forKey: pin.identifier as NSString)
        return image
    }
    
    private func localImageForPin(pin: Pin) -> UIImage? {
        let pinLocation = ImageLoader.currentUserCacheDirectoryPath()! + "/\(pin.identifier)"
        guard let imageData = FileManager.default.contents(atPath: pinLocation) else {
            return nil
        }
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        self.imageCache.setObject(image, forKey: pin.identifier as NSString)
        return image
    }
    
    private func fetchRemoteImageForPin(pin: Pin, completion:@escaping (_ image: UIImage?) -> Void) {
        guard let url = NSURL(string: pin.imagePath) else { return }
        URLSession.shared.dataTask(with: url as URL) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else {
                    completion(nil)
                    return
                }
            self.imageCache.setObject(image, forKey: pin.identifier as NSString)
            let pinLocation = ImageLoader.currentUserCacheDirectoryPath()! + "/\(pin.identifier)"
            FileManager.default.createFile(atPath: pinLocation, contents: data, attributes: nil)
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
