//
//  UserProfile.swift
//  Picture Map
//
//  Created by Tigger on 7/20/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import Foundation

import Firebase
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn

class UserProfile {
    
    class func currentUser() -> FIRUser? {
        return FIRAuth.auth()?.currentUser
    }
    
    class func logOut() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print("Error logging out: \(error)")
        }
    }
    
}
