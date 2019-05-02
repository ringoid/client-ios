//
//  LMMProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

enum FeedType: Int
{
    case unknown = 0
    case likesYou = 1
    case matches = 2
    case hellos = 3
    case inbox = 4
    case sent = 5
}

class LMMProfile: Profile
{
    @objc dynamic var defaultSortingOrderPosition: Int = 0
    @objc dynamic var notSeen: Bool = true
    @objc dynamic var type: Int = 0
    
    let messages: List<Message> = List<Message>()
}

enum MessagingState
{
    case empty
    case outcomingOnly
    case chatUnread
    case chatRead
}

extension LMMProfile
{
    var state: MessagingState
    {
        guard !self.messages.isEmpty else { return .empty }

        var isSentByNotMe: Bool = false
        self.messages.forEach({ message in
            if !message.wasYouSender {  isSentByNotMe = true }
        })
        
        if isSentByNotMe {
            return self.notSeen ? .chatUnread : .chatRead
        }
        
        return .outcomingOnly
    }
}
