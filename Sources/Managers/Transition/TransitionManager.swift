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
    fileprivate let filter: FilterManager
    fileprivate var destinationObserver: AnyObserver<SourceFeedType>!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, lmm: LMMManager, filter: FilterManager)
    {
        self.db = db
        self.lmm = lmm
        self.filter = filter
        
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
        case .likesYou: self.db.updateOrder(lmm.likesYou.value, silently: true)        
        case .messages: self.db.updateOrder(lmm.messages.value, silently: true)
        case .inbox: self.db.updateOrder(lmm.inbox.value, silently: true)
        case .sent: self.db.updateOrder(lmm.sent.value, silently: true)
        }
        
        switch from {
        case .likesYou:
            self.lmm.allLikesYouProfilesCount.accept( self.lmm.allLikesYouProfilesCount.value - 1)
            self.lmm.allMessagesProfilesCount.accept( self.lmm.allMessagesProfilesCount.value + 1)
            
            if self.filter.isFilteringEnabled.value {
                self.lmm.filteredLikesYouProfilesCount.accept( self.lmm.filteredLikesYouProfilesCount.value - 1)
                self.lmm.filteredMessagesProfilesCount.accept( self.lmm.filteredMessagesProfilesCount.value + 1)
            }
            break
        default: break
        }
        
        // Manually transitioned profile is already seen
        self.lmm.markAsTransitioned(profile.id, in: to)
        
        profile.write({ obj in
            (obj as? LMMProfile)?.type = to.feedType().rawValue
            (obj as? LMMProfile)?.notSeen = false
        })
        
        switch to {
        case .likesYou, .messages: self.db.forceUpdateLMM()
        case .inbox, .sent: self.db.forceUpdateMessages()
        }
        
        guard from != to.feedType() else { return }
        
        switch from {
        case .likesYou, .messages: self.db.forceUpdateLMM()
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
        case .likesYou: self.db.updateOrder(lmm.likesYou.value, silently: true)
        case .messages: self.db.updateOrder(lmm.messages.value, silently: true)
        case .inbox: self.db.updateOrder(lmm.inbox.value, silently: true)
        case .sent: self.db.updateOrder(lmm.sent.value, silently: true)
        }
        
        let duplicate = profile.duplicate()
        
        duplicate.write({ [weak self] obj in
            (obj as? LMMProfile)?.type = to.feedType().rawValue
            (obj as? LMMProfile)?.notSeen = false
            self?.db.checkObjectsForUpdates([obj!])
        })
        
        switch to {
        case .likesYou, .messages: self.db.forceUpdateLMM()
        case .inbox, .sent: self.db.forceUpdateMessages()
        }
        
        guard from != to.feedType() else { return }
        
        // Manually transitioned profile is already seen
        self.lmm.markAsTransitioned(profile.id, in: to)
        
        switch from {
        case .likesYou, .messages: self.db.forceUpdateLMM()
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
        case .messages: return .messages
        case .inbox: return .inbox
        case .sent: return .sent
        }
    }
}
