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
var dailySchedule: [[Any]] = []
var scheduleName = ""
var specialMessage = ""

    /*
        Period = [PeriodName, stringStartTime, stringEndTime, 24hrStartTime, 24hrEndTime] filled after loadSchedule is completed
        Filled durring loadSchedule()
        string times are like 8:00
        real times are 15.40
    */

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var ref: DatabaseReference!
    var update: DispatchWorkItem?
    
    
    @IBOutlet weak var testName: UILabel!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadSchedule()
    }
    
    func loadSchedule(){
        dailySchedule.removeAll()

        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

        
            let cal = Calendar.current
            let components = cal.dateComponents([ .month, .day, .weekday], from: Date())
            print("date\(components)")
            let currentMonth = components.month ?? 0
            let currentDay = components.day ?? 0
            
            self?.ref.child("dates").child("\(currentMonth)-\(currentDay)").observeSingleEvent(of: .value, with: { (snapshot) in
                let date = snapshot.value as? NSDictionary ?? [:]
                var schedule = "regular"
                
                if date != [:]{
                    schedule = date["schedule"] as? String ?? "failed"
                    specialMessage = date["reason"] as? String ?? "failed"
                }
                
                self?.ref.child("schedules").child(schedule).observeSingleEvent(of: .value, with: { (snapshot) in
                    let scheduleDict = snapshot.value as? NSDictionary ?? [:]
                    
                    for (key,value) in scheduleDict{
                        let key = key as? String ?? "noString"
                        if key != "name" {
                            let value = value as? NSDictionary ?? [:]
                            let startTime = value["start"] as? Double  ?? 0
                            let endTime = value["end"] as? Double  ?? 0
                            
                            var realStartTime = startTime
                            var realEndTime = endTime
                            if(startTime<6.3){ //times 1:00 - 6:29 are assumed to be PM 6:30 - 12:59 are AM
                                realStartTime = startTime + 12
                                realEndTime = endTime + 12
                            }
                            
                            dailySchedule.append([key,startTime,endTime,realStartTime,realEndTime])
                        }else{
                            scheduleName = value as? String ?? "kool"
                        }
                    }
                    
                    dailySchedule = dailySchedule.sorted{($0[3] as! Double) < ($1[3]as! Double)}
                    
                    let formater = NumberFormatter()
                    formater.decimalSeparator = ":"
                    formater.maximumFractionDigits = 2
                    formater.minimumFractionDigits = 2
                    formater.roundingMode = .halfUp
                    

                    for i in 0..<dailySchedule.endIndex {
                        dailySchedule[i][1] = formater.string(from: NSNumber(value: dailySchedule[i][1] as? Double ?? 0)) ?? "0"
                        dailySchedule[i][2] = formater.string(from: NSNumber(value: dailySchedule[i][2] as? Double ?? 0)) ?? "0"
                    }
                    
                   // print(dailySchedule)
                    print("loaded")
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.scheduleCollectionView.reloadData()
                        self?.testName.text = scheduleName + " " + todaysDate
                        print("updated")
                    }
                    
                    print("leave before")
                    group.leave()
                    print("leave after")
                    
                }) { (error) in
                    print(error.localizedDescription)
                    }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
    
        
        group.notify(queue: .main) {
            self.scheduleNewUpdate()
        }
    }
    
    
    
    func scheduleNewUpdate(){
        update?.cancel()
        
        update = DispatchWorkItem { [weak self] in
            
            DispatchQueue.main.async { [weak self] in
                let formater = DateFormatter()
                formater.dateFormat = "HH.mm"
                let currentTime = formater.string(from: Date())
                
            }

            self?.scheduleNewUpdate()
        }
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5,execute: update!)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dailySchedule.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TestCollectionViewCell
        cell.startTime.text = dailySchedule[indexPath.row][1] as? String
        cell.endTime.text = dailySchedule[indexPath.row][2] as? String
        return cell
    }
    
}

