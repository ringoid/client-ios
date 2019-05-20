//
//  DeletionFeedbackViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 17/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class DeletionFeedbackViewController: BaseViewController
{
    var onDelete: ((String)->())?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var noUndoLabel: UILabel!
    @IBOutlet fileprivate weak var suggestLabel: UILabel!
    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet fileprivate weak var cancelBtn: UIButton!
    @IBOutlet fileprivate weak var deleteBtn: UIButton!
    @IBOutlet fileprivate weak var bottomSeparatorConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var midSeparatorConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.bottomSeparatorConstraint.constant = 0.5
        self.midSeparatorConstraint.constant = 0.5
        
        self.textView.layer.borderColor = UIColor.lightGray.cgColor
        self.textView.layer.borderWidth = 1.0
        self.textView.layer.cornerRadius = 4.0
        self.textView.becomeFirstResponder()
    }
    
    override func updateTheme() {}
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_account_delete_dialog_title".localized()
        self.noUndoLabel.text = "common_uncancellable".localized()
        self.suggestLabel.text = "feedback_before_deletion".localized()
        self.cancelBtn.setTitle("button_cancel".localized(), for: .normal)
        self.deleteBtn.setTitle("button_delete".localized(), for: .normal)
    }
    
    // MARK: - Actionss
    
    @IBAction func cancelAction()
    {        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteAction()
    {
        self.dismiss(animated: true, completion: nil)
        self.onDelete?(self.textView.text ?? "")        
    }
}
