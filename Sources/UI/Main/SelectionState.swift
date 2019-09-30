//
//  SelectionState.swift
//  ringoid
//
//  Created by Victor Sukochev on 30/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum SelectionState {
    case search
    case likes
    case chats
    case profile
    
    case searchAndFetch
    case searchAndFetchFirstTime
    case profileAndPick
    case profileAndFetch
    case profileAndAsk
    case likeAndFetch
    case chat(String)
}

extension SelectionState: Equatable
{
    static func == (lhs: Self, rhs: Self) -> Bool
    {
        switch (lhs, rhs) {
            case (.search, .search): return true
            case (.likes, .likes): return true
            case (.chats, .chats): return true
            case (.profile, .profile): return true
            
            case (.searchAndFetch, .searchAndFetch): return true
            case (.searchAndFetchFirstTime, .searchAndFetchFirstTime): return true
            case (.profileAndPick, .profileAndPick): return true
            case (.profileAndFetch, .profileAndFetch): return true
            case (.profileAndAsk, .profileAndAsk): return true
            case (.likeAndFetch, .likeAndFetch): return true
            
            case (.chat(let leftId), .chat(let rightId)): return leftId == rightId
            
            default: return false
        }
    }
}
