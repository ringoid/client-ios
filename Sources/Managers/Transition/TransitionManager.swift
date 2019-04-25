//
//  TransitionManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class TransitionManager
{
    fileprivate let db: DBService
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService)
    {
        self.db = db
    }
    
    func removeAsLiked(_ profile: Profile)
    {
        self.db.delete([profile]).subscribe().disposed(by: self.disposeBag)
    }
    
    func move(_ profile: LMMProfile, to: LMMType)
    {
        profile.write({ obj in
            (obj as? LMMProfile)?.type = to.feedType().rawValue
        })
        self.db.forceUpdateLMM()
    }
}

extension LMMType
{
    func feedType() -> FeedType
    {
        switch self {
        case .likesYou:
            return .likesYou
            
        case .matches:
            return .matches
            
        case .messages:
            return .messages
        }
    }
}
