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
   
    @IBOutlet weak var upcomingCollectionView: UICollectionView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        upcomingCollectionView.delegate = self
        upcomingCollectionView.dataSource = self
        
        upcomingCollectionView.backgroundColor = .red
        
        print(upcomingSpecialDays)
    }
    
    // MARK: Database
//    func loadSchedule(){
//       upcomingSpecialDaysTemp.removeAll()
//
//       let group = DispatchGroup()
//       group.enter()
//
//
//       DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//           let formater = DateFormatter()
//           formater.dateFormat = "MMdd"
//           let dateKey = formater.string(from: Date())
//
//
//
//           self?.ref.child("dates").observeSingleEvent(of: .value, with: { (snapshot) in
//               let dates = snapshot.value as? [String:NSDictionary] ?? [:]
//               var schedule = "regular"
//
//               for (key,values) in dates{
//                   let formater = DateFormatter()
//                   formater.dateFormat = "MMdd"
//                   let refDate = formater.date(from: key)!
//
//                   var todayDateDouble = Double(formater.string(from: Date())) ?? 0
//                   var refDateDouble = Double(key) ?? 0
//
//                   if(refDateDouble < 700){ //uptill july is previous year
//                       refDateDouble += 1200
//                   }
//                   if(todayDateDouble < 700){ //uptill july is previous year
//                       todayDateDouble += 1200
//                   }
//                   if(refDateDouble - todayDateDouble > 0){
//                       formater.dateFormat = "M/dd"
//                       let dateFormatted = formater.string(from: refDate)
//                       upcomingSpecialDaysTemp.append([dateFormatted,values["name"] ?? "falied",refDateDouble])
//                   }
//               }
//               upcomingSpecialDaysTemp = upcomingSpecialDaysTemp.sorted{($0[2] as! Double) < ($1[2]as! Double)}
//
//               print(upcomingSpecialDaysTemp)
//
//
//        }
    
    // MARK: Collection View

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           return upcomingSpecialDays.count
       }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "upcomingCell", for: indexPath) as! UpcomingCell
        let cellText = "\(upcomingSpecialDays[indexPath.row][0]) \(upcomingSpecialDays[indexPath.row][1])"
        cell.dateLabel.text = cellText
        cell.backgroundColor = .blue
        return cell
   }
    
    // MARK: Segue
    

}
