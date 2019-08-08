//
//  ReachabilityServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 01/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Reachability
import RxReachability
import RxSwift
import RxCocoa


class ReachabilityServiceDefault: ReachabilityService
{
    var isInternetAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    
    fileprivate let reachability = Reachability()
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    deinit
    {
        self.reachability?.stopNotifier()
    }
    
    init()
    {
        try? self.reachability?.startNotifier()
        
        self.setupBindings()
    }
    
    func check() -> Observable<Bool>
    {
        return self.isInternetAvailable.asObservable().delay(.milliseconds(350), scheduler: MainScheduler.instance)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.reachability?.rx.isReachable.asObservable().subscribe(onNext: { [weak self] state in
            self?.isInternetAvailable.accept(state)
        }).disposed(by: self.disposeBag)
    }
}
