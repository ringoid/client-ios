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
    case messages = 3
    case inbox = 4
    case sent = 5
}

class LMMProfile: Profile
{
    @objc dynamic var defaultSortingOrderPosition: Int = 0
    @objc dynamic var notSeen: Bool = true
    @objc dynamic var notRead: Bool = true
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
            return self.notRead ? .chatUnread : .chatRead
        }
        
        return .outcomingOnly
    }
}

extension LMMProfile
{
    func duplicate() -> LMMProfile
    {
        let profile = LMMProfile()
        profile.id = self.id
        profile.photos.append(objectsIn: self.photos)
        profile.messages.append(objectsIn: self.messages)
        
        if self.realm?.isInWriteTransaction == true {
            self.realm?.add(profile)
        } else {
            try? self.realm?.write { [weak self] in
                self?.realm?.add(profile)
            }
        }
        
        return profile
    }
}
