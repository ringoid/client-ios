//
//  LocationManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class LocationManager
{
    var isGranted: Bool
    {
        return self.location.isGranted.value
    }
    
    fileprivate let location: LocationService
    fileprivate let actions: ActionsManager
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ location: LocationService, actions: ActionsManager)
    {
        self.location = location
        self.actions = actions
        
        self.setupBindings()
    }
    
    func requestPermissionsIfNeeded()
    {
        self.location.requestPermissionsIfNeeded()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.location.locations.subscribe(onNext: { [weak self] loc in
            self?.actions.addLocation(loc)
        }).disposed(by: self.disposeBag)
    }
}
