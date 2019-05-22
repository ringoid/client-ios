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
    var onSend: ((String)->())?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet fileprivate weak var cancelBtn: UIButton!
    @IBOutlet fileprivate weak var sendBtn: UIButton!
    @IBOutlet fileprivate weak var bottomSeparatorConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var midSeparatorConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.bottomSeparatorConstraint.constant = 1.0
        self.midSeparatorConstraint.constant = 1.0
        
        self.textView.layer.borderColor = UIColor.lightGray.cgColor
        self.textView.layer.borderWidth = 1.0
        self.textView.layer.cornerRadius = 4.0
        self.textView.text = UserDefaults.standard.string(forKey: "suggestion_feedback_text")
        self.textView.becomeFirstResponder()
    }
    
    override func updateTheme() {
        
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "feedback_suggest_improvements".localized()
        self.cancelBtn.setTitle("button_cancel".localized(), for: .normal)
        self.sendBtn.setTitle("button_suggest".localized(), for: .normal)
    }
    
    // MARK: - Actionss
    
    @IBAction func cancelAction()
    {
        UserDefaults.standard.set(self.textView.text, forKey: "suggestion_feedback_text")
        UserDefaults.standard.synchronize()
        
        self.textView.resignFirstResponder()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendAction()
    {
        UserDefaults.standard.set("", forKey: "suggestion_feedback_text")
        UserDefaults.standard.synchronize()
        
        if let text = self.textView.text {
            self.onSend?(text)
            
            self.textView.resignFirstResponder()
            
            self.dismiss(animated: true, completion: nil)
        }
    }
}

