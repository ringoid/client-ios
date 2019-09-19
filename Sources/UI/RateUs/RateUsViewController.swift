//
//  RateUsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class RateUsViewController: BaseViewController
{
    override func updateTheme() {}
    
    // MARK: - Actions
    
    @IBAction func notNowAction()
    {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func rateAction()
    {
        self.moveToAppstore()
    }
    
    // MARK: -
    
    fileprivate func moveToAppstore()
    {
        let urlStr = "https://itunes.apple.com/app/id1453136158?action=write-review"
        guard let writeReviewURL = URL(string: urlStr) else { return }
        
        UIApplication.shared.open(writeReviewURL)
    }
}
