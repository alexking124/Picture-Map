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
    var dateTaken: NSNumber = NSNumber.init(value: Date.distantPast.timeIntervalSinceReferenceDate)
    
    init() {}
    
    init(snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String:Any]
        self.latitude = snapshotValue["latitude"] as! CLLocationDegrees
        self.longitude = snapshotValue["longitude"] as! CLLocationDegrees
        self.imagePath = snapshotValue["imagePath"] as! String
        self.title = snapshotValue["title"] as! String
        self.description = snapshotValue["description"] as! String
        if let date = snapshotValue["date"] as? NSNumber {
            self.dateTaken = date
        }
        self.identifier = snapshot.key
    }
    
    func getDate() -> Date {
        return Date(timeIntervalSinceReferenceDate: dateTaken.doubleValue)
    }
    
    func changeDate(_ date: Date) {
        dateTaken = NSNumber.init(value: date.timeIntervalSinceReferenceDate)
    }
    
    func metadataDictionary() -> Dictionary<String, Any> {
        let pinMetadata = ["identifier": identifier,
                           "latitude": latitude,
                           "longitude": longitude,
                           "imagePath": imagePath,
                           "title": title,
                           "description": description,
                           "date": dateTaken] as [String : Any]
        return pinMetadata
    }
    
}
