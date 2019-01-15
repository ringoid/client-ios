//
//  Action.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

enum ActionType: String
{
    case like = "LIKE"
    case view = "VIEW"
    case block = "BLOCK"
    case unlike = "UNLIKE"
    case message = "MESSAGE"
    case openChat = "OPEN_CHAT"
}

enum SourceFeedType: String
{
    case newFaces = "new_faces"
    case whoLikedMe = "who_liked_me"
    case matches = "matches"
    case messages = "messages"
}

class Action: Object
{
    @objc dynamic var type: String!
    @objc dynamic var actionTime: Date!
    @objc dynamic var targetPhotoId: String!
    @objc dynamic var targetUserId: String!
    @objc dynamic var sourceFeed: String!
}
