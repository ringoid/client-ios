//
//  FilterManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

class FilterManager
{
    let minAge: BehaviorRelay<Int?> = BehaviorRelay<Int?>(value: nil)
    let maxAge: BehaviorRelay<Int?> = BehaviorRelay<Int?>(value: nil)
    let maxDistance: BehaviorRelay<Int?> = BehaviorRelay<Int?>(value: nil)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init()
    {
        self.loadSettings()
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func loadSettings()
    {
        self.minAge.accept((UserDefaults.standard.object(forKey: "filter_min_age") as? NSNumber)?.intValue)
        self.maxAge.accept((UserDefaults.standard.object(forKey: "filter_max_age") as? NSNumber)?.intValue)
        self.maxDistance.accept((UserDefaults.standard.object(forKey: "filter_max_distance") as? NSNumber)?.intValue)
    }
    
    fileprivate func setupBindings()
    {
        self.minAge.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "filter_min_age")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        self.maxAge.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "filter_max_age")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        self.maxDistance.subscribe(onNext: { value in            
            UserDefaults.standard.set(value, forKey: "filter_max_distance")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
    }
}
