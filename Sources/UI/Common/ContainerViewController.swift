//
//  ContainerViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController
{
    func embed(_ vc: UIViewController)
    {
        self.view.subviews.forEach({ $0.removeFromSuperview() })
        self.children.forEach({ $0.removeFromParent() })
        
        self.addChild(vc)
        
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.frame = self.view.bounds
        self.view.addSubview(vc.view)
        vc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        vc.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        vc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
}
