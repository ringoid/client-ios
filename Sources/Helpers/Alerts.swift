//
//  Alerts.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

func showError(_ error: Error, vc: UIViewController)
{
    let description = (error as NSError).localizedDescription
    
    guard (error as NSError).code == ErrorType.visible.rawValue else {
        log(description, level: .high)
        
        return
    }
    
    let alertVC = UIAlertController(title: "Error", message: description, preferredStyle: .alert)
    alertVC.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
    
    vc.present(alertVC, animated: true, completion: nil)
}
