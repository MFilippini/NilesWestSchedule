//
//  Color.swift
//  NilesWestSchedule
//
//  Created by Michael Filippini on 10/17/19.
//  Copyright © 2019 Michael Filippini. All rights reserved.
//

import Foundation
import UIKit

// getColor(type: Main)
// color["accent"]
// color["dark"][paletteID]
// color["light"][paletteID]

var colorIndex = 0
// 0 = mainColorsNW



extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    static var main: UIColor{
        let mainColorList = [UIColor.init(red: 210, green: 43, blue: 35)]
        return mainColorList[colorIndex]
    }
    
    static var background: UIColor{
        let backgroundColorList = [UIColor.init(red: 65, green: 65, blue: 65)]
        return backgroundColorList[colorIndex]
    }
    
    static var accent: UIColor{
        let accentColorList = [UIColor.init(red: 65, green: 65, blue: 65)]
        return accentColorList[colorIndex]
    }
    
    
    
}
