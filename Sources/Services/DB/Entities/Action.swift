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
    @objc dynamic var extraData: Data?
}

// MARK: - Like

extension Action
{
    func likeData() -> Int?
    {
        guard self.type == ActionType.like.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let likeCount = jsonDict["likeCount"] as? Int else { return nil }
        
        return likeCount
    }
    
    func setLikeData(_ likeCount: Int)
    {
        guard self.type == ActionType.like.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["likeCount": likeCount])
    }
}

// MARK: - View

extension Action
{
    func viewData() -> (viewCount: Int, viewTimeSec: Int)?
    {
        guard self.type == ActionType.view.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let viewCount = jsonDict["viewCount"] as? Int else { return nil }
        guard let viewTimeSec = jsonDict["viewTimeSec"] as? Int else { return nil }
        
        return (viewCount: viewCount, viewTimeSec: viewTimeSec)
    }
    
    func setViewData(viewCount: Int, viewTimeSec: Int)
    {
        guard self.type == ActionType.view.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["viewCount": viewCount, "viewCount": viewCount])
    }
}

// MARK: - Block

extension Action
{
    func blockData() -> Int?
    {
        guard self.type == ActionType.block.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let blockReasonNum = jsonDict["blockReasonNum"] as? Int else { return nil }
        
        return blockReasonNum
    }
    
    func setBlockData(_ blockReasonNum: Int)
    {
        guard self.type == ActionType.block.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["blockReasonNum": blockReasonNum])
    }
}

// MARK: - Message

extension Action
{
    func messageData() -> String?
    {
        guard self.type == ActionType.message.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let text = jsonDict["text"] as? String else { return nil }
        
        return text
    }
    
    func setMessageData(_ text: String)
    {
        guard self.type == ActionType.message.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["text": text])
    }
}

// MARK: - Open chat

extension Action
{
    func openChatData() -> (openChatCount: Int, openChatTimeSec: Int)?
    {
        guard self.type == ActionType.openChat.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let openChatCount = jsonDict["openChatCount"] as? Int else { return nil }
        guard let openChatTimeSec = jsonDict["openChatTimeSec"] as? Int else { return nil }
        
        return (openChatCount: openChatCount, openChatTimeSec: openChatTimeSec)
    }
    
    func setOpenChatData(openChatCount: Int, openChatTimeSec: Int)
    {
        guard self.type == ActionType.openChat.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["openChatCount": openChatCount, "openChatTimeSec": openChatTimeSec])
    }
}
