//
//  Pin.swift
//  Picture Map
//
//  Created by Tigger on 7/14/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import CoreLocation
import Foundation
import Firebase

class Pin {
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var imagePath: String = ""
    var title: String = ""
    var description: String = ""
    
    init() {}
    
    init(snapshot: FIRDataSnapshot) {
        self.latitude = snapshot.value!["latitude"] as! CLLocationDegrees
        self.longitude = snapshot.value!["longitude"] as! CLLocationDegrees
        self.imagePath = snapshot.value!["imagePath"] as! String
        self.title = snapshot.value!["title"] as! String
        self.description = snapshot.value!["description"] as! String
    }
    
    class func parseFromSnapshot(snapshot: FIRDataSnapshot) -> [Pin] {
        var pins = [Pin]()
        
        for child in snapshot.children {
            let pin = Pin.init(snapshot: child as! FIRDataSnapshot)
            pins.append(pin)
        }
        
        return pins
    }
}