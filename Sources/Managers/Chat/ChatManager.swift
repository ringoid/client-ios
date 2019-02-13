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
    
    init(_ db: DBService, actionsManager: ActionsManager)
    {
        self.db = db
        self.actionsManager = actionsManager
    }
    
    func send(_ text: String, profile: LMMProfile, photo: Photo, source: SourceFeedType)
    {
        let message = Message()
        message.text = text
        message.wasYouSender = true

        profile.write { obj in
            let lmmProfile = obj as? LMMProfile
            lmmProfile?.messages.append(message)
            lmmProfile?.notSeen = false
        }

        self.actionsManager.add(
            .message(text: text),
            profile: profile.actionInstance(),
            photo: photo.actionInstance(),
            source: source
        )
        
        self.actionsManager.commit()
    }
    
    func markAsRead(_ profile: LMMProfile)
    {
        profile.write { [weak profile] _ in
            profile?.notSeen = false
        }
    }
}