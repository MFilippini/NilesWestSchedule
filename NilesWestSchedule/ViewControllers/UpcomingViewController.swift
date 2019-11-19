//
//  UpcomingViewController.swift
//  NilesWestSchedule
//
//  Created by Michael Filippini on 9/24/19.
//  Copyright © 2019 Michael Filippini. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase


class UpcomingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
   
    @IBOutlet weak var upcomingDaysCollectionView: UICollectionView!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    
    var ref: DatabaseReference!
    var scheduleType: [Any] = []
    var specialSchedule: [[Any]] = []
    var specialScheduleTemp: [[Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
        upcomingDaysCollectionView.delegate = self
        upcomingDaysCollectionView.dataSource = self
        
        ref = Database.database().reference()
        
        
        print("!!!!!")
        print(scheduleType)
        print("!!!!!")
        specialScheduleTemp.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.ref.child("schedules").child(self?.scheduleType[3] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                let scheduleDict = snapshot.value as? NSDictionary ?? [:]
                for (key,value) in scheduleDict{
                    let key = key as? String ?? "noString"
                    if key != "name" {
                        let value = value as? NSDictionary ?? [:]
                        let startTime = value["start"] as? Double  ?? 0
                        let endTime = value["end"] as? Double  ?? 0
                        var realStartTime = startTime
                        var realEndTime = endTime
                        if startTime < 6.3 { //times 1:00 - 6:29 are assumed to be PM 6:30 - 12:59 are AM
                            realStartTime = startTime + 12
                            realEndTime = endTime + 12
                        }
                        print([key,startTime,endTime,realStartTime,realEndTime])
                        print("dasjkfhajisfh")
                        self?.specialScheduleTemp.append([key,startTime,endTime,realStartTime,realEndTime])
                    }
                }
                

                self?.specialScheduleTemp = self?.specialScheduleTemp.sorted{($0[3] as! Double) < ($1[3]as! Double)} ?? [[]]
                
                

                let formater = NumberFormatter()
                formater.decimalSeparator = ":"
                formater.maximumFractionDigits = 2
                formater.minimumFractionDigits = 2
                formater.roundingMode = .halfUp

                for i in 0..<self!.specialScheduleTemp.endIndex {
                    self!.specialScheduleTemp[i][1] = formater.string(from: NSNumber(value: self!.specialScheduleTemp[i][1] as? Double ?? 0)) ?? "0"
                    self!.specialScheduleTemp[i][2] = formater.string(from: NSNumber(value: self!.specialScheduleTemp[i][2] as? Double ?? 0)) ?? "0"
                }

                self?.specialSchedule = self?.specialScheduleTemp ?? [[]]
                
                self?.upcomingDaysCollectionView.reloadData()

            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        
        

    }
    
    // MARK: Collection View

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            if collectionView == upcomingDaysCollectionView {
                //print(specialSchedule)
                //return specialSchedule.count
                return 0
            } else {
                return 0
            }
       }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TestCollectionViewCell
        
        cell.periodLabel.text = specialSchedule[indexPath.row][1] as? String
        
        return cell
        
   }
    
    // MARK: Segue
    

}
