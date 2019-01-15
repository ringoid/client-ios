//
//  ActionsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

enum FeedAction
{
    case like(likeCount: Int)
    case view(viewCount: Int, viewTimeSec: Int)
    case block(blockReasonNum: Int)
    case unlike
    case message(text: String)
    case openChat(openChatCount: Int, openChatTimeSec: Int)
}

class ActionsManager
{
    let db: DBService
    let apiService: ApiService
    
    init(_ db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
    }
    
    func add(_ action: FeedAction)
    {
        
    }
}
