//
//  UpcomingViewController.swift
//  NilesWestSchedule
//
//  Created by Michael Filippini on 9/24/19.
//  Copyright © 2019 Michael Filippini. All rights reserved.
//

import UIKit

class UpcomingViewController: UIViewController {
    
    @IBOutlet weak var segueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func segueWithButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
 

}
