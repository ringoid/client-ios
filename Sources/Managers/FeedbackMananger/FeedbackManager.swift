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

enum FeedbackSource: String {
    case deleteAccount = "DeleteAccount"
    case settings = "SuggestFromSettings"
    case chat = "CloseChat"
}

class FeedbackManager
{
    var modalManager: ModalUIManager!
    var apiService: ApiService!
    var profileManager: UserProfileManager!
    var deviceService: DeviceService!
    
    private init() {}
    
    static let shared = FeedbackManager()
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    func showSuggestion(_ from: UIViewController)
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "settings_feedback_vc") as! SettingsFeedbackViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.onSend = { [weak self] text in
            self?.send(text, source: .settings)
            self?.modalManager.hide(animated: true)
        }
        
        vc.onCancel = { [weak self] in
            
        }
        
        from.present(vc, animated: true, completion: nil)
    }
    
    func showDeletion(_ onDelete: (()->())?, from: UIViewController)
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "deletion_feedback_vc") as! DeletionFeedbackViewController
        vc.modalPresentationStyle = .fullScreen
        vc.onDelete = { [weak self] text in
            self?.send(text, source: .deleteAccount)
            self?.modalManager.hide(animated: true)
            onDelete?()
        }
        
        vc.onCancel = { [weak self] in
            
        }
        
        from.present(vc, animated: true, completion: nil)
    }
    
    // MARK: -
    
    fileprivate func send(_ text: String, source: FeedbackSource)
    {
        guard text.count > 0 else { return }
        
        let calendar = Calendar.current
        let daysPassed: Int = Int(Date().timeIntervalSince(self.profileManager.creationDate.value) / (60.0 * 60.0 * 24.0))
        let age = calendar.component(.year, from: Date()) - self.profileManager.yob.value
        let gender = self.profileManager.gender.value == .male ? "Male" : "Female"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let creationStr = dateFormatter.string(from: self.profileManager.creationDate.value)
        let template =
"""
*\(gender)* \(self.profileManager.yob.value) (\(age)) from `\(source.rawValue)`

> "\(text)"

iOS \(self.deviceService.appVersion)
\(self.deviceService.deviceName)

`\(self.apiService.customerId.value)` \(creationStr) (\(daysPassed) days ago)
"""
        
        let params: [String: Any] = [
            "channel": "CJDASTGTC",
            "text": template,
        ]
        
        RxAlamofire.request(.post, "https://slack.com/api/chat.postMessage", parameters: params, encoding: JSONEncoding.default, headers: [
            "Authorization": "Bearer xoxp-457467555377-521724314999-637621413061-869a987bacc19dc81fb258a633b34100",
            ]).subscribe().disposed(by: self.disposeBag)
    }
}
