//
//  ViewController.swift
//  NilesWestSchedule
//
//  Created by Michael Filippini on 8/19/19.
//  Copyright © 2019 Michael Filippini. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

var todaysDate = ""
class ViewController: UIViewController {
    
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setColors()
        loadSchedule()
    }
    
    func setColors(){
        
    }
    
    func loadSchedule(){
        let cal = Calendar.current
        let components = cal.dateComponents([ .month, .day, .weekday], from: Date())
        print("date\(components)")
        let currentMonth = components.month ?? 0
        let currentDay = components.day ?? 0
        print("\(currentMonth)-\(currentDay)")
        
        ref.child("schedules").child("regular").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            print(value)
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
}

