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
    case viewChat = "VIEW_CHAT"
    case location = "LOCATION"
}

enum SourceFeedType: String
{
    case newFaces = "new_faces"
    case whoLikedMe = "who_liked_me"
    case matches = "matches"
    case hellos = "hellos"
    case inbox = "inbox"
    case sent = "sent"
    case profile = "profile"
    case chat = "chat"
}

class Action: DBServiceObject
{
    @objc dynamic var type: String!
    @objc dynamic var actionTime: Date!
    @objc dynamic var sourceFeed: String!
    @objc dynamic var extraData: Data?
    
    @objc dynamic var profile: ActionProfile? = nil
    @objc dynamic var photo: ActionPhoto? = nil
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
    func viewData() -> (viewCount: Int, viewTime: Int)?
    {
        guard self.type == ActionType.view.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let viewCount = jsonDict["viewCount"] as? Int else { return nil }
        guard let viewTime = jsonDict["viewTimeMillis"] as? Int else { return nil }
        
        return (viewCount: viewCount, viewTime: viewTime)
    }
    
    func setViewData(viewCount: Int, viewTime: Int)
    {
        guard self.type == ActionType.view.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["viewCount": viewCount, "viewTimeMillis": viewTime])
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
    func viewChatData() -> (viewChatCount: Int, viewChatTime: Int)?
    {
        guard self.type == ActionType.viewChat.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let viewChatCount = jsonDict["viewChatCount"] as? Int else { return nil }
        guard let viewChatTime = jsonDict["viewChatTimeMillis"] as? Int else { return nil }
        
        return (viewChatCount: viewChatCount, viewChatTime: viewChatTime)
    }
    
    func setViewChatData(viewChatCount: Int, viewChatTime: Int)
    {
        guard self.type == ActionType.viewChat.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: ["viewChatCount": viewChatCount, "viewChatTimeMillis": viewChatTime])
    }
}

// MARK: - Location

extension Action
{
    func locationData() -> Location?
    {
        guard self.type == ActionType.location.rawValue else { return nil }
        guard let jsonData = self.extraData, let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else { return nil }
        guard let lat = jsonDict["lat"] as? Double else { return nil }
        guard let lon = jsonDict["lon"] as? Double else { return nil }
        
        return Location(
            latitude: lat,
            longitude: lon
        )
    }
    
    func setLocationData(_ location: Location)
    {
        guard self.type == ActionType.location.rawValue else { return }
        
        self.extraData = try? JSONSerialization.data(withJSONObject: [
            "lat": location.latitude,
            "lon": location.longitude
            ])
    }
}
