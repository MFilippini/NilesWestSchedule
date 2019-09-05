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
var unNeededClasses: [String] = []
var usersSchedule: [[Any]] = []
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
    var timeTillNextUpdate: Double?
    var nextUpdateTime: String?
    
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
                    
                    unNeededClasses = ["Early Bird A","Early Bird B","Early Bird C"]
                    
                    for period in dailySchedule{
                        let periodName = period[0]
                        if !(unNeededClasses.contains("\(periodName)")){
                            usersSchedule.append(period)
                        }
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.scheduleCollectionView.reloadData()
                        self?.testName.text = scheduleName + " " + todaysDate
                    }
                    group.leave()
                    
                }) { (error) in
                    print(error.localizedDescription)
                    }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        group.notify(queue: .main) {
            self.timeTillNextUpdate = 0.001
            self.scheduleNewUpdate()
        }
    }
    
    
    
    func scheduleNewUpdate(){
        update?.cancel()
        
        update = DispatchWorkItem { [weak self] in
            //remember to go to MAIN thread to change UI label
            /*
             
             DispatchQueue.main.async { [weak self] in
                label.text = IDK What to say
             }

            */
            DispatchQueue.global(qos: .background).sync {
                let formater = DateFormatter()
                formater.dateFormat = "HH.mm"
                let currentTime = Double(formater.string(from: Date())) ?? 0
                
                if(usersSchedule[0][3] as? Double ?? 0 >= currentTime){
                    print("before school")
                    self?.nextUpdateTime = "\(usersSchedule[0][3])"
                }
                else if(usersSchedule[usersSchedule.count - 1][4] as? Double ?? 0 <= currentTime){
                    print("school is over")
                    self?.nextUpdateTime = "\(usersSchedule[0][3])"
                }else{
                    for period in usersSchedule{
                        // timeIndex 3
                        if(currentTime < (period[3] as? Double ?? 0) ){
                            print("Time till period start: \(currentTime - (period[3] as? Double ?? 0)) ")
                            self?.nextUpdateTime = "\(period[3])"
                            break
                            
                        }else if(currentTime < (period[4] as? Double ?? 0) ){
                            print("Time till period end: \(currentTime - (period[4] as? Double ?? 0))")
                            self?.nextUpdateTime = "\(period[4])"
                            break
                        }
                    }
                }
                // get time till update in seconds
                
                let startDouble = Double(currentTime)
                let endDouble = Double((self?.nextUpdateTime)!)
                
                let startInt = Double(Int(startDouble))
                let endInt = Double(Int(endDouble!))
                
                let secondsTimeStart = startInt*3600 + (startDouble - startInt)*6000
                let secondsTimeEnd = endInt*3600 + (endDouble! - endInt)*6000
                
                self?.timeTillNextUpdate = abs(secondsTimeEnd - secondsTimeStart)
            }
            self?.scheduleNewUpdate()
        }
        
        print("Time till next Update: \(timeTillNextUpdate!)")
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + abs(timeTillNextUpdate!),execute: update!)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersSchedule.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TestCollectionViewCell
        cell.startTime.text = usersSchedule[indexPath.row][1] as? String
        cell.endTime.text = usersSchedule[indexPath.row][2] as? String
        return cell
    }
    
}

