//
//  ViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

extension UIViewController
{
    var isVisible: Bool { return self.isViewLoaded && (self.view.window != nil) }
}
