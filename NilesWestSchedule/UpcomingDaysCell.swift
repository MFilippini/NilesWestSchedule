//
//  UpcomingDaysCell.swift
//  
//
//  Created by Alush Benitez on 10/23/19.
//

import UIKit

class UpcomingDaysCell: UICollectionViewCell {
    
    
    @IBOutlet var firstSpecialDayButton: UIButton!
    @IBOutlet var secondSpecialDayButton: UIButton!
    @IBOutlet var thirdSpecialDayButton: UIButton!
    
    @IBOutlet var firstLabel: UILabel!
    @IBOutlet var secondLabel: UILabel!
    @IBOutlet var thirdLabel: UILabel!
    
    var buttons: [UIButton] = []
    var labels: [UILabel] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buttons = [firstSpecialDayButton, secondSpecialDayButton, thirdSpecialDayButton]
        labels = [firstLabel, secondLabel, thirdLabel]
        // Initialization code
    }

}
