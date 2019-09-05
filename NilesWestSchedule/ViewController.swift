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
var usersSchedule: [[Any]] = []
var dailyScheduleTemp: [[Any]] = []
var usersScheduleTemp: [[Any]] = []

var unNeededClasses: [String] = []
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
    var timeTillNextClass: String?
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var scheduleDiscriptorLabel: UILabel!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
//        scheduleCollectionView.layer.cornerRadius = 7
//        scheduleCollectionView.layer.shadowColor = UIColor.gray.cgColor
//        scheduleCollectionView.layer.shadowOffset = CGSize(width: 0, height: 1.2)
//        scheduleCollectionView.layer.shadowRadius = 1.2
//        scheduleCollectionView.layer.shadowOpacity = 1.0
//        scheduleCollectionView.layer.masksToBounds = false
//        scheduleCollectionView.layer.shadowPath = UIBezierPath(roundedRect:scheduleCollectionView.bounds, cornerRadius: 7).cgPath
        
        for family: String in UIFont.familyNames
        {
            print(family)
            for names: String in UIFont.fontNames(forFamilyName: family)
            {
                print("== \(names)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadSchedule()
    }
    
    func loadSchedule(){
        dailyScheduleTemp.removeAll()
        usersScheduleTemp.removeAll()
        
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
                            
                            dailyScheduleTemp.append([key,startTime,endTime,realStartTime,realEndTime])
                        }else{
                            scheduleName = value as? String ?? "kool"
                        }
                    }
                    
                    dailyScheduleTemp = dailyScheduleTemp.sorted{($0[3] as! Double) < ($1[3]as! Double)}
                    
                    let formater = NumberFormatter()
                    formater.decimalSeparator = ":"
                    formater.maximumFractionDigits = 2
                    formater.minimumFractionDigits = 2
                    formater.roundingMode = .halfUp
                    
                    for i in 0..<dailyScheduleTemp.endIndex {
                        dailyScheduleTemp[i][1] = formater.string(from: NSNumber(value: dailyScheduleTemp[i][1] as? Double ?? 0)) ?? "0"
                        dailyScheduleTemp[i][2] = formater.string(from: NSNumber(value: dailyScheduleTemp[i][2] as? Double ?? 0)) ?? "0"
                    }
                    
                    unNeededClasses = ["Early Bird A","Early Bird B","Period 1"]
                    
                    for period in dailyScheduleTemp{
                        let periodName = period[0]
                        if !(unNeededClasses.contains("\(periodName)")){
                            usersScheduleTemp.append(period)
                        }
                    }
                    
                    usersSchedule = usersScheduleTemp
                    dailySchedule = dailyScheduleTemp
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.scheduleCollectionView.reloadData()
                        self?.scheduleDiscriptorLabel.text = scheduleName + " " + todaysDate
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
            DispatchQueue.global(qos: .userInitiated).sync {
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
                
                //subtract seconds already in minute
                
                let formaterSec = DateFormatter()
                formaterSec.dateFormat = "ss.SSS"
                let secPassed = Double(formaterSec.string(from: Date())) ?? 0
                self?.timeTillNextClass = "\(secondsTimeEnd - secondsTimeStart - secPassed)"
                self?.timeTillNextUpdate = 60 - secPassed
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
        cell.backgroundColor = .clear
        let colorTop = UIColor(red: 203.0/255.0, green: 45.0/255.0, blue: 62.0/255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 239.0/255.0, green: 71.0/255.0, blue: 58.0/255.0, alpha: 1.0).cgColor
        
//        let gradient = CAGradientLayer()
//        gradient.colors = [colorTop, colorBottom]
//        gradient.locations = [0.0, 1.0]
//        gradient.frame = cell.bounds
//        cell.layer.insertSublayer(gradient, at: 0)
        cell.layer.cornerRadius = 7
        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 1.2)
        cell.layer.shadowRadius = 1.2
        cell.layer.shadowOpacity = 1.0
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius: 16).cgPath
        cell.layer.cornerRadius = 16
        cell.backgroundColor = .white
        cell.startTime.text = dailySchedule[indexPath.row][0] as? String
        cell.endTime.text = String(dailySchedule[indexPath.row][1] as? String ?? "e") + " - " + String(dailySchedule[indexPath.row][2] as? String ?? "w")
        return cell
    }
    
}

