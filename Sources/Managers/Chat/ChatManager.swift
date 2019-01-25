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

        try? profile.realm?.write({
            profile.messages.append(message)
        })
        
        self.actionsManager.add(.message(text: text), profile: profile, photo: photo, source: source)
    }
}
