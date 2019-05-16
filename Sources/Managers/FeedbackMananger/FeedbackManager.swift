//
//  FeedbackManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation
import Alamofire
import RxAlamofire
import RxSwift
import RxCocoa

class FeedbackManager
{
    var modalManager: ModalUIManager!
    
    private init() {}
    
    static let shared = FeedbackManager()
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    func showFromSettings()
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "settings_feedback_vc") as! SettingsFeedbackViewController
        vc.onSend = { [weak self] text in
            self?.send(text)
            self?.modalManager.hide(animated: true)
        }
        
        vc.onCancel = { [weak self] in
            self?.modalManager.hide(animated: true)
        }
        
        self.modalManager.show(vc, animated: true)
    }
    
    // MARK: -
    
    fileprivate func send(_ text: String)
    {
        let params: [String: Any] = [
            "channel": "CJDASTGTC",
            "text": text,
        ]
        
        RxAlamofire.request(.post, "https://slack.com/api/chat.postMessage", parameters: params, encoding: JSONEncoding.default, headers: [
            "Authorization": "Bearer xoxp-457467555377-521724314999-637621413061-869a987bacc19dc81fb258a633b34100",
            ]).subscribe().disposed(by: self.disposeBag)
    }
}
