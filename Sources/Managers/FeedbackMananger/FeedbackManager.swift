//
//  FeedbackManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class FeedbackManager
{
    var modalManager: ModalUIManager!
    
    private init() {}
    
    static let shared = FeedbackManager()
    
    func showFromSettings()
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "settings_feedback_vc") as! SettingsFeedbackViewController
        vc.onSend = { [weak self] text in
            self?.modalManager.hide(animated: true)
        }
        
        vc.onCancel = { [weak self] in
            self?.modalManager.hide(animated: true)
        }
        
        self.modalManager.show(vc, animated: true)
    }
}
