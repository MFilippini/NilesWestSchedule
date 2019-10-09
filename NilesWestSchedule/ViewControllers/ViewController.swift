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
var upcomingSpecialDays: [[Any]] = []
var upcomingSpecialDaysTemp: [[Any]] = []
var unNeededClasses: [String] = []
var scheduleName = ""
var specialMessage = ""
var buttonDirection: Bool?
var collapsingButtonArray: [UIButton] = []

    /*
        Schedules----------
            - daily has all classes
            - users has only classes that pertain to users
 
            Period = [PeriodName, stringStartTime, stringEndTime, 24hrStartTime, 24hrEndTime] filled after loadSchedule is completed
            Filled durring loadSchedule()
            string times are like 8:00
            real times are 15.40
 
        Special Days----------
            date= ["5/5","Late Start",1709]
            is sorted and dates before today are removed
 
    */

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var ref: DatabaseReference!
    var update: DispatchWorkItem?
    var timeTillNextUpdate: Double?
    //var nextUpdateTime: String? //use for making 4 min till end
    var timeTillNextClass: Double?
    var iconsList: [UIImage] = []
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var scheduleDiscriptorLabel: UILabel!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    @IBOutlet weak var masterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
        
        //change date
        let formater = DateFormatter()
        formater.dateFormat = "EEEE, M/d"
        dateLabel.text = formater.string(from: Date())

        
        addIcons()
        buttonSetup()
        addButtonsToArray()

//        scheduleCollectionView.layer.cornerRadius = 7
//        scheduleCollectionView.layer.shadowColor = UIColor.gray.cgColor
//        scheduleCollectionView.layer.shadowOffset = CGSize(width: 0, height: 1.2)
//        scheduleCollectionView.layer.shadowRadius = 1.2
//        scheduleCollectionView.layer.shadowOpacity = 1.0
//        scheduleCollectionView.layer.masksToBounds = false
//        scheduleCollectionView.layer.shadowPath = UIBezierPath(roundedRect:scheduleCollectionView.bounds, cornerRadius: 7).cgPath
        
        for family: String in UIFont.familyNames
        {
          //  print(family)
            for names: String in UIFont.fontNames(forFamilyName: family)
            {
                //print("== \(names)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadSchedule()
    }
    
    // MARK: Buttons

    func addIcons(){
        if #available(iOS 13.0, *) {
            
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .large)
            
            let cal = UIImage(systemName: "calendar", withConfiguration: config)!
            let gear = UIImage(systemName: "gear", withConfiguration: config)!
            let bell = UIImage(systemName: "bell", withConfiguration: config)!
            
            self.iconsList = [cal,gear,bell]
        } else {
            // Fallback on earlier versions
        }
        print("icons:\(iconsList)")
    }
    
    
    func buttonSetup(){
        masterButton.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.84, alpha: 1)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .large)

        masterButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        masterButton.layer.cornerRadius = 27
        buttonDirection = true
        masterButton.addTarget(self, action: #selector(expandButton), for: .touchUpInside)
        masterButton.addTarget(self, action: #selector(holdDownMaster), for: .touchDown)
        masterButton.addTarget(self, action: #selector(cancelHoldMaster), for: .touchDragExit)
        
    }
    
    func addButtonsToArray(){
        let start = masterButton.frame
        let color = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.84, alpha: 1)
        
        let movingViewZero = UIButton(frame: start)
        collapsingButtonArray.append(movingViewZero)
        movingViewZero.tag = 0
        
        let movingViewOne = UIButton(frame: start)
        collapsingButtonArray.append(movingViewOne)
        movingViewOne.tag = 1
        
        let movingViewTwo = UIButton(frame: start)
        collapsingButtonArray.append(movingViewTwo)
        movingViewTwo.tag = 2
        
        for button in collapsingButtonArray{
            button.backgroundColor = color
            button.tintColor = .black
            button.setImage(iconsList[button.tag], for: .normal)
            button.layer.cornerRadius = 25
            button.addTarget(self, action: #selector(subButton), for: .touchUpInside)
            button.addTarget(self, action: #selector(holdDownSub), for: .touchDown)
            button.addTarget(self, action: #selector(cancelHoldSub), for: .touchDragExit)

        }
    }

    @objc func holdDownMaster(sender: UIButton){
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)

        UIView.animate(withDuration: 0.02,
            animations: {
                sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                sender.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.7, alpha: 1)
            }, completion: nil)
    }
    
    
    @objc func holdDownSub(sender: UIButton){
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)

        UIView.animate(withDuration: 0.05,
            animations: {
                sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                sender.backgroundColor = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.7, alpha: 1)
        }, completion: nil)
    }
    
    @objc func subButton(sender: UIButton){
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.9)

        print(sender.tag)
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.84, alpha: 1)
        }
        
        
        //[cal,gear,bell]
        if(sender.tag == 0){
            performSegue(withIdentifier: "toUpcomingSegue", sender: nil)
        }
        else if(sender.tag == 1){
            performSegue(withIdentifier: "toSettingsSegue", sender: nil)

        }else{
            performSegue(withIdentifier: "toNotificationsSegue", sender: nil)
        }
        
    }

    @objc func cancelHoldSub(sender: UIButton){
        UIView.animate(withDuration: 0.02) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 149/360.0, saturation: 0.82, brightness: 0.84, alpha: 1)
        }
    }
    
    @objc func cancelHoldMaster(sender: UIButton){
        UIView.animate(withDuration: 0.02) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.84, alpha: 1)
        }
    }
    
    
    @objc func expandButton(sender: UIButton!) {
        let masterCenter = masterButton.center
        let masterCenterX = masterButton.center.x
        let masterCenterY = masterButton.center.y
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.9)

        UIView.animate(withDuration: 0.02) {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = UIColor(hue: 205/360.0, saturation: 0.83, brightness: 0.84, alpha: 1)
        }
        
        if(buttonDirection!){
            for button in collapsingButtonArray{
                self.view.insertSubview(button, belowSubview: masterButton)
            }
            
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.83, options: [.curveEaseInOut,.allowUserInteraction], animations: {
                
                collapsingButtonArray[0].center = CGPoint(x: masterCenterX, y: masterCenterY-125)
                collapsingButtonArray[1].center = CGPoint(x: masterCenterX-88.388, y: masterCenterY-88.388)
                collapsingButtonArray[2].center = CGPoint(x: masterCenterX-125, y: masterCenterY)
                
            }, completion: nil)
        }else{
            
            UIView.animate(withDuration: 0.2, animations: {
                
                collapsingButtonArray[0].center = masterCenter
                collapsingButtonArray[1].center = masterCenter
                collapsingButtonArray[2].center = masterCenter
                
            }, completion: { (finished: Bool) in
                for button in collapsingButtonArray{
                    button.removeFromSuperview()
                }
            })
        }
        buttonDirection = !(buttonDirection!)
    }
    
    // MARK: Database

    func loadSchedule(){
        print("Load Schedule")
        dailyScheduleTemp.removeAll()
        usersScheduleTemp.removeAll()
        upcomingSpecialDaysTemp.removeAll()
        
        
        let group = DispatchGroup()
        group.enter()
        
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            let formater = DateFormatter()
            formater.dateFormat = "MMdd"
            let dateKey = formater.string(from: Date())
            
            
            
            self?.ref.child("dates").observeSingleEvent(of: .value, with: { (snapshot) in
                let dates = snapshot.value as? [String:NSDictionary] ?? [:]
                var schedule = "regular"
                
                for (key,values) in dates{
                    let formater = DateFormatter()
                    formater.dateFormat = "MMdd"
                    let refDate = formater.date(from: key)!
                    
                    var todayDateDouble = Double(formater.string(from: Date())) ?? 0
                    var refDateDouble = Double(key) ?? 0
                    
                    if(refDateDouble < 700){ //uptill july is previous year
                        refDateDouble += 1200
                    }
                    if(todayDateDouble < 700){ //uptill july is previous year
                        todayDateDouble += 1200
                    }
                    if(refDateDouble - todayDateDouble > 0){
                        formater.dateFormat = "M/dd"
                        let dateFormatted = formater.string(from: refDate)
                        upcomingSpecialDaysTemp.append([dateFormatted,values["name"] ?? "falied",refDateDouble])
                    }
                }
                upcomingSpecialDaysTemp = upcomingSpecialDaysTemp.sorted{($0[2] as! Double) < ($1[2]as! Double)}

                print(upcomingSpecialDaysTemp)
                
                if dates[dateKey] != nil{
                    let date = dates[dateKey]
                    schedule = date?["schedule"] as? String ?? "failed"
                    specialMessage = date?["reason"] as? String ?? "failed"
                }
                
                print(schedule)
                
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
                    upcomingSpecialDays = upcomingSpecialDaysTemp
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.scheduleCollectionView.reloadData()
                       // self?.upcomingDates.reloadData()
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
                
                let formaterSec = DateFormatter()
                formaterSec.dateFormat = "ss.SSS"
                let secPassed = Double(formaterSec.string(from: Date())) ?? 0
                self?.timeTillNextUpdate = 60 - secPassed
                
                if(usersSchedule[0][3] as? Double ?? 0 >= currentTime){
                    
                    //change date
                    let formater = DateFormatter()
                    formater.dateFormat = "EEEE, M/d"
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.dateLabel.text = formater.string(from: Date())
                    }
                    
                    print("before school")
                    self?.setTimeToNextClass(endTime: "\(usersSchedule[0][3])")
                    print("first Class at\(self?.timeTillNextClass)")
                    self?.timeTillNextUpdate = self?.timeTillNextClass
                }
                else if(usersSchedule[usersSchedule.count - 1][4] as? Double ?? 0 <= currentTime){
                    print("school is over")
                    self?.setTimeToNextClass(endTime: "24.00")
                    self?.timeTillNextUpdate = self?.timeTillNextClass

                    print("next Update at end of day\(self?.timeTillNextClass)")
                }else{
                    for period in usersSchedule{
                        // timeIndex 3
                        if(currentTime < (period[3] as? Double ?? 0) ){
                            self?.setTimeToNextClass(endTime: "\(period[3])")
                            
                            if((self?.timeTillNextClass as! Double) <= 60.0){
                                  let formaterSec = DateFormatter()
                                  formaterSec.dateFormat = "0.SSS"
                                  let milSecPassed = Double(formaterSec.string(from: Date())) ?? 0
                                  self?.timeTillNextUpdate = 1 - milSecPassed
                            }
                            
                            print("Time till period start: \(self?.timeTillNextClass!)")
                            break
                        }else if(currentTime < (period[4] as? Double ?? 0) ){
                            self?.setTimeToNextClass(endTime: "\(period[4])")
                            print("Time till period end: \(self?.timeTillNextClass!)")
                            
                            if((self?.timeTillNextClass as! Double) <= 60.0){
                                let formaterSec = DateFormatter()
                                formaterSec.dateFormat = "0.SSS"
                                let milSecPassed = Double(formaterSec.string(from: Date())) ?? 0
                                self?.timeTillNextUpdate = 1 - milSecPassed
                            }
                            break
                        }
                    }
                }
            }
            self?.scheduleNewUpdate()
        }
        
        let formater = NumberFormatter()
        formater.decimalSeparator = ":"
        formater.maximumFractionDigits = 2
        formater.minimumFractionDigits = 2
        formater.roundingMode = .halfUp
        
        
        print("Time till next Update: \(timeTillNextUpdate!)")
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + abs(timeTillNextUpdate!),execute: update!)
    }
    
    func setTimeToNextClass (endTime: String){
        let formater = DateFormatter()
        formater.dateFormat = "HH.mm"
        let currentTime = Double(formater.string(from: Date())) ?? 0
        
        let startDouble = Double(currentTime)
        let endDouble = Double(endTime)
    
        let startInt = Double(Int(startDouble))
        let endInt = Double(Int(endDouble!))
    
        let secondsTimeStart = startInt*3600 + (startDouble - startInt)*6000
        let secondsTimeEnd = endInt*3600 + (endDouble! - endInt)*6000
    
        //subtract seconds already in minute
    
        let formaterSec = DateFormatter()
        formaterSec.dateFormat = "ss.SSS"
        let secPassed = Double(formaterSec.string(from: Date())) ?? 0
        self.timeTillNextClass =  (secondsTimeEnd - secondsTimeStart - secPassed)
    }
    
    
    // MARK: Collection Views

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == scheduleCollectionView {
            return usersSchedule.count
        }
        return upcomingSpecialDays.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == scheduleCollectionView {
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
            cell.startTime.text = usersSchedule[indexPath.row][0] as? String
            cell.endTime.text = String(usersSchedule[indexPath.row][1] as? String ?? "e") + " - " + String(usersSchedule[indexPath.row][2] as? String ?? "w")
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "upcomingCell", for: indexPath) as! UpcomingCell
            let cellText = "\(upcomingSpecialDays[indexPath.row][0]) \(upcomingSpecialDays[indexPath.row][1])"
            cell.dateLabel.text = cellText
            return cell
        }

    }
    
    // MARK: Seuge
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let masterCenter = masterButton.center
        let masterCenterX = masterButton.center.x
        let masterCenterY = masterButton.center.y
        
        if(!buttonDirection!){
            UIView.animate(withDuration: 0.2, animations: {
                
                collapsingButtonArray[0].center = masterCenter
                collapsingButtonArray[1].center = masterCenter
                collapsingButtonArray[2].center = masterCenter
                
            }, completion: { (finished: Bool) in
                for button in collapsingButtonArray{
                    button.removeFromSuperview()
                }
            })
            buttonDirection = !(buttonDirection!)
        }
    }
    
    
}

