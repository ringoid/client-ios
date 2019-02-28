//
//  ExtendedTouchesView.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ExtendedTouchesView: UIView
{
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hittedView = super.hitTest(point, with: event)
        if hittedView == self { return self.subviews.last }
        
        return hittedView
    }
}
