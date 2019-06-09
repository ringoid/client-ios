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
    var afterTransition: Bool = false
    var destination: Observable<SourceFeedType>!
    
    fileprivate let db: DBService
    fileprivate let lmm: LMMManager
    fileprivate var destinationObserver: AnyObserver<SourceFeedType>!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, lmm: LMMManager)
    {
        self.db = db
        self.lmm = lmm
        
        self.destination = Observable<SourceFeedType>.create({ [weak self] observer -> Disposable in
            self?.destinationObserver = observer
            
            return Disposables.create()
        })
    }
    
    func removeAsLiked(_ profile: Profile)
    {
        self.afterTransition = true
        self.db.delete([profile]).subscribe().disposed(by: self.disposeBag)
    }
    
    func move(_ profile: LMMProfile, to: LMMType)
    {
        self.afterTransition = true
        self.destinationObserver.onNext(to.sourceType())
        
        guard let from = FeedType(rawValue: profile.type) else { return }
        
        switch to {
        case .likesYou: self.db.updateOrder(lmm.likesYou.value)
        case .matches: self.db.updateOrder(lmm.matches.value)
        case .messages: self.db.updateOrder(lmm.messages.value)
        case .inbox: self.db.updateOrder(lmm.inbox.value)
        case .sent: self.db.updateOrder(lmm.sent.value)
        }
        
        profile.write({ [weak self] obj in
            (obj as? LMMProfile)?.type = to.feedType().rawValue
            (obj as? LMMProfile)?.notSeen = false
            self?.db.checkObjectsForUpdates([obj!])
        })
        
        switch to {
        case .likesYou, .matches, .messages: self.db.forceUpdateLMM()
        case .inbox, .sent: self.db.forceUpdateMessages()
        }
        
        guard from != to.feedType() else { return }
        
        switch from {
        case .likesYou, .matches, .messages: self.db.forceUpdateLMM()
        case .inbox, .sent: self.db.forceUpdateMessages()
        case .unknown: return
        }
    }
    
    func moveDuplicate(_ profile: LMMProfile, to: LMMType)
    {
        self.afterTransition = true
        self.destinationObserver.onNext(to.sourceType())
        
        guard let from = FeedType(rawValue: profile.type) else { return }
        
        switch to {
        case .likesYou: self.db.updateOrder(lmm.likesYou.value)
        case .matches: self.db.updateOrder(lmm.matches.value)
        case .messages: self.db.updateOrder(lmm.messages.value)
        case .inbox: self.db.updateOrder(lmm.inbox.value)
        case .sent: self.db.updateOrder(lmm.sent.value)
        }
        
        let duplicate = profile.duplicate()
        
        duplicate.write({ [weak self] obj in
            (obj as? LMMProfile)?.type = to.feedType().rawValue
            (obj as? LMMProfile)?.notSeen = false
            self?.db.checkObjectsForUpdates([obj!])
        })
        
        switch to {
        case .likesYou, .matches, .messages: self.db.forceUpdateLMM()
        case .inbox, .sent: self.db.forceUpdateMessages()
        }
        
        guard from != to.feedType() else { return }
        
        switch from {
        case .likesYou, .matches, .messages: self.db.forceUpdateLMM()
        case .inbox, .sent: self.db.forceUpdateMessages()
        case .unknown: return
        }
    }
}

extension LMMType
{
    func feedType() -> FeedType
    {
        switch self {
        case .likesYou: return .likesYou
        case .matches: return .matches
        case .messages: return .messages
        case .inbox: return .inbox
        case .sent: return .sent
        }
    }
}
