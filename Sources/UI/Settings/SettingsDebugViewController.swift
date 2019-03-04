//
//  SettingsDebugViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsDebugViewController: BaseViewController
{
    @IBOutlet fileprivate weak var logTextView: UITextView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.logTextView.text = LogService.shared.asText()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onCopy()
    {
        UIPasteboard.general.string = LogService.shared.asClipboardText()
        
        let alertVC = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_close".localized(), style: .default, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
}
