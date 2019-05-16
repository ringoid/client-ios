//
//  SettingsFeedbackViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsFeedbackViewController: BaseViewController
{
    var onCancel: (()->())?
    var onSend: ((String)->())?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet fileprivate weak var cancelBtn: UIButton!
    @IBOutlet fileprivate weak var sendBtn: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func updateLocale()
    {
        
    }
    
    // MARK: - Actionss
    
    @IBAction func cancelAction()
    {
        self.onCancel?()
    }
    
    @IBAction func sendAction()
    {
        if let text = self.textView.text {
            self.onSend?(text)
        }
    }
}

