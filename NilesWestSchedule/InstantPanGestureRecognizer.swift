//
//  InstantPanGestureRecognizer.swift
//  NilesWestSchedule
//
//  Created by Michael Filippini on 10/23/19.
//  Copyright © 2019 Michael Filippini. All rights reserved.
//

import UIKit

class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
}
