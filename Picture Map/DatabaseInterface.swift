//
//  DatabaseInterface.swift
//  Picture Map
//
//  Created by Alex King on 12/21/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import Foundation

import FirebaseAuth
import FirebaseDatabase


class DatabaseInterface {
    
    static let shared = DatabaseInterface()
    
    private var currentUserID: String {
        let currentUser = FIRAuth.auth()?.currentUser
        
        guard let userID = currentUser?.uid else {
            fatalError("Couldn't get the current user!")
        }
        return userID
    }
    
    private var databaseReference: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    private var pinsDatabaseReference: FIRDatabaseReference {
        return databaseReference.child("pins").child(currentUserID)
    }
    
    private var usageDatabaseReference: FIRDatabaseReference {
        return databaseReference.child("limit").child(currentUserID)
    }
    
    func insertNewPin() -> FIRDatabaseReference {
        
        let pinReference = pinsDatabaseReference.childByAutoId()
        self.decrementLimit()
        
        return pinReference
    }
    
    func updatePin(_ pinID: String, metadata: Any?) {
        let pinReference = pinsDatabaseReference.child(pinID)
        pinReference.setValue(metadata)
    }
    
    func deletePin(_ pinID: String) {
        let pinReference = pinsDatabaseReference.child(pinID)
        pinReference.removeValue()
        self.incrementLimit()
    }
    
    private func decrementLimit() {
        usageDatabaseReference.observeSingleEvent(of: .value, with: { [unowned self] (snapshot) in
            guard let value = snapshot.value else {
                return
            }
            self.usageDatabaseReference.setValue((value as AnyObject).integerValue - 1)
        })
    }
    
    private func incrementLimit() {
        usageDatabaseReference.observeSingleEvent(of: .value, with: { [unowned self] (snapshot) in
            guard let value = snapshot.value else {
                return
            }
            self.usageDatabaseReference.setValue((value as AnyObject).integerValue + 1)
        })
    }
    
}
