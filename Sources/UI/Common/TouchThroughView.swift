//
//  TouchThroughView.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class TouchThroughView: UIView
{
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        let view = super.hitTest(point, with: event)
        return (view != self) ? view : nil
    }
}


class TouchThroughWindow: UIWindow
{
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        let view = super.hitTest(point, with: event)
        return (view != self) ? view : nil
    }
}
