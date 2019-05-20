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
        }
        
        from.present(vc, animated: true, completion: nil)
    }
    
    func showDeletion(_ onDelete: (()->())?, from: UIViewController)
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "deletion_feedback_vc") as! DeletionFeedbackViewController
        vc.modalPresentationStyle = .fullScreen
        vc.onDelete = { [weak self] text in
            self?.send(text, source: .deleteAccount)
            onDelete?()
        }

        from.present(vc, animated: true, completion: nil)
    }
    
    // MARK: -
    
    fileprivate func send(_ text: String, source: FeedbackSource)
    {
        guard text.count > 0 else { return }
        
        var reportText: String = ""
        
        if let gender = self.profileManager.gender.value, let yob = self.profileManager.yob.value {
            let age =  Calendar.current.component(.year, from: Date()) - yob
            reportText.append("*\(age) \(gender == .male ? "M" : "F")* ")
        }
        
        reportText.append("from `\(source.rawValue)`\n\n")
        reportText.append("> \"\(text.replacingOccurrences(of: "\n", with: "\n>"))\"\n\n")
        reportText.append("iOS \(self.deviceService.appVersion)\n\(self.deviceService.deviceName)\n\n")
        reportText.append("`\(self.apiService.customerId.value)`")
        
        if let creationDate = self.profileManager.creationDate.value {
            let daysPassed: Int = Int(Date().timeIntervalSince(creationDate) / (60.0 * 60.0 * 24.0))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let creationStr = dateFormatter.string(from: creationDate)
            
            reportText.append(" createdAt \(creationStr) (\(daysPassed) days ago)")
        }

        let params: [String: Any] = [
            "channel": "CJDASTGTC",
            "text": reportText,
        ]
        
        RxAlamofire.request(.post, "https://slack.com/api/chat.postMessage", parameters: params, encoding: JSONEncoding.default, headers: [
            "Authorization": "Bearer xoxp-457467555377-521724314999-637621413061-869a987bacc19dc81fb258a633b34100",
            ]).subscribe().disposed(by: self.disposeBag)
    }
}
