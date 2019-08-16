//
//  AchivementManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class AchivementManager
{
    let text: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    fileprivate var likesCount: Int = 0
    fileprivate var lastLikesAchivementCount: Int = 0
    fileprivate let likesAchievements: [Int] = [5, 10, 25, 50, 100]
    
    init()
    {
        self.loadCounters()
    }
    
    func addLikes(_ count: Int)
    {
        self.likesCount += count
        UserDefaults.standard.set(self.likesCount, forKey: "achievement_likes_count")
        self.checkLikesAchivement()
    }
    
    func reset()
    {
        self.likesCount = 0
        self.lastLikesAchivementCount = 0
        
        UserDefaults.standard.removeObject(forKey: "achievement_likes_count")
        UserDefaults.standard.removeObject(forKey: "achievement_likes_malestone")
    }
    
    // MARK: -
    
    fileprivate func loadCounters()
    {
        self.likesCount = UserDefaults.standard.integer(forKey: "achievement_likes_count")
        self.lastLikesAchivementCount = UserDefaults.standard.integer(forKey: "achievement_last_likes_count")
    }
    
    fileprivate func checkLikesAchivement()
    {
        var maxAchivementCount: Int? = nil
        for achievementCount in self.likesAchievements {
            guard achievementCount > self.lastLikesAchivementCount else { continue }
            guard achievementCount <= self.likesCount else { continue }

            self.lastLikesAchivementCount = achievementCount
            UserDefaults.standard.set(achievementCount, forKey: "achievement_last_likes_count")
            maxAchivementCount = achievementCount
        }
        
        guard let count = maxAchivementCount else { return }
        
        self.text.accept(String(format: "achievement_likes_malestone".localized(), count))
    }
}
