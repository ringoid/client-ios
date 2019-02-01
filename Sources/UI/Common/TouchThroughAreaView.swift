//
//  TouchThroughAreaView.swift
//  ringoid
//
//  Created by Victor Sukochev on 01/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class TouchThroughAreaView: UIView
{
    var area: CGRect?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        let view = super.hitTest(point, with: event)
        
        guard let frame = area else { return view }
        
        return frame.contains(point) ? nil : view
    }
}
