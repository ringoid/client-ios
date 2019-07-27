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
    case popup = "SuggestFromProfilePopup"
    case profileFields = "SuggestFromProfileSettings"
    case notificationsSettings = "SuggestFromNotificationsSettings"
    case filtersSettings = "SuggestFromFiltersSettings"
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
    
    func showSuggestion(_ from: UIViewController, source: FeedbackSource, feedSource: SourceFeedType?)
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "settings_feedback_vc") as! SettingsFeedbackViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.onSend = { [weak self] text in
            guard text.count > 0 else { return }
            
            self?.send(text, source: source, feedSource: feedSource)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self?.showThanksAlert(from)
            })
        }
        
        from.present(vc, animated: false, completion: nil)
    }
    
    func showDeletion(_ onDelete: (()->())?, from: UIViewController)
    {
        let vc = Storyboards.feedback().instantiateViewController(withIdentifier: "deletion_feedback_vc") as! DeletionFeedbackViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.onDelete = { [weak self] text in
            self?.send(text, source: .deleteAccount, feedSource: nil)
            onDelete?()
        }

        from.present(vc, animated: false, completion: nil)
    }
    
    // MARK: -
    
    fileprivate func send(_ text: String, source: FeedbackSource, feedSource: SourceFeedType?)
    {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return }
        
        var reportText: String = ""
        
        if let gender = self.profileManager.gender.value, let yob = self.profileManager.yob.value {
            let age =  Calendar.current.component(.year, from: Date()) - yob
            reportText.append("*\(age) \(gender == .male ? "M" : "F")* ")
        }
        
        if let feedSource = feedSource {
            reportText.append("from `\(source.rawValue)` - `\(feedSource.rawValue)`\n\n")
        } else {
            reportText.append("from `\(source.rawValue)`\n\n")
        }
        
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
            "channel": self.profileManager.gender.value == .female ?  "CL9UG0HU0" : "CL9UV062Z",
            "text": reportText,
        ]
        
        RxAlamofire.request(.post, "https://slack.com/api/chat.postMessage", parameters: params, encoding: JSONEncoding.default, headers: [
            "Authorization": "Bearer xoxp-457467555377-521724314999-637621413061-869a987bacc19dc81fb258a633b34100",
            ]).subscribe(onError: { _ in
                SentryService.shared.send(.feedbackFailed, params: ["text": text])
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showThanksAlert(_ from: UIViewController)
    {
        let alertVC = UIAlertController(title: nil, message: "feedback_thanks_alert".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_ok".localized(), style: .default, handler: nil))
        from.present(alertVC, animated: true, completion: nil)
    }
}
