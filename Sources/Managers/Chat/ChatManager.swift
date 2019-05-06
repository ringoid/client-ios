//
//  ChatManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class ChatManager
{
    let db: DBService
    let actionsManager: ActionsManager
    let scenario: AnalyticsScenarioManager
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, actionsManager: ActionsManager, scenario: AnalyticsScenarioManager)
    {
        self.db = db
        self.actionsManager = actionsManager
        self.scenario = scenario
    }
    
    func send(_ text: String, profile: LMMProfile, photo: Photo, source: SourceFeedType)
    {
        self.scenario.checkFirstMessageSent(source)
        
        let message = Message()
        message.text = text
        message.wasYouSender = true
        message.orderPosition = profile.messages.sorted(byKeyPath: "orderPosition").last?.orderPosition ?? 0

        self.db.lmmDuplicates(profile.id).subscribe(onSuccess: { profiles in
            profiles.forEach {
                $0.write { obj in
                    let lmmProfile = obj as? LMMProfile
                    lmmProfile?.messages.append(message)
                }
                
                self.db.forceMarkAsSeen($0)
            }
        }).disposed(by: self.disposeBag)
        

        let photoId = photo.id
        guard let actionProfile = profile.actionInstance(), let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first else { return }
        
        self.actionsManager.messageActionProtected(
            text,
            profile: actionProfile,
            photo: actionPhoto,
            source: source
        )
    }
    
    func markAsRead(_ profile: LMMProfile)
    {
        self.db.forceMarkAsSeen(profile)
    }
}
