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
    var identifier: String = ""
    var dateTaken: Date = Date.distantPast
    
    init() {}
    
    init(snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String:Any]
        self.latitude = snapshotValue["latitude"] as! CLLocationDegrees
        self.longitude = snapshotValue["longitude"] as! CLLocationDegrees
        self.imagePath = snapshotValue["imagePath"] as! String
        self.title = snapshotValue["title"] as! String
        self.description = snapshotValue["description"] as! String
        if let date = snapshotValue["date"] as? NSNumber {
            self.dateTaken = Date(timeIntervalSinceReferenceDate: date.doubleValue)
        }
        self.identifier = snapshot.key
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
