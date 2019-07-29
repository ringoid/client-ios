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
    let isFilteringEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init()
    {
        self.loadSettings()
        self.setupBindings()
    }
    
    func checkDefaultValues(_ gender: Sex, age: Int)
    {
        guard self.minAge.value == nil, self.maxAge.value == nil, self.maxDistance.value == nil else { return }
        
        var minAge: Int = 18
        var maxAge: Int = 55
        
        if gender == .male {
            minAge = age - 10
            maxAge = age
        } else {
            minAge = age
            maxAge = age + 10
        }
        
        guard minAge > 18 else {
            self.minAge.accept(18)
            self.maxAge.accept(27)
            
            return
        }
        
        guard maxAge < 55 else {
            self.maxAge.accept(nil)
            self.minAge.accept(46)
            
            return
        }
        
        self.minAge.accept(minAge)
        self.maxAge.accept(maxAge)
    }
    
    func reset()
    {
        self.minAge.accept(nil)
        self.maxAge.accept(nil)
        self.maxDistance.accept(nil)
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
