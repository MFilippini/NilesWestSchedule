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
