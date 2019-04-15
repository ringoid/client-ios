//
//  LocationServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift
import CoreLocation

class LocationServiceDefault: NSObject, LocationService
{
    var locations: Observable<Location>!
    var isGranted: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate var locationsObserver: AnyObserver<Location>!
    fileprivate let lm: CLLocationManager = CLLocationManager()
    
    func requestPermissionsIfNeeded()
    {
        guard !self.isGranted.value else { return }
        
        self.lm.requestWhenInUseAuthorization()
    }
    
    override init()
    {
        super.init()
        
        self.locations = Observable.create({ [weak self] observer -> Disposable in
            self?.locationsObserver = observer
            
            return Disposables.create()
        })
        
        self.lm.delegate = self
    }
}

extension LocationServiceDefault: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        log("Location failed: \(error.localizedDescription)", level: .high)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        let isGrantedDesc = (status == .authorizedWhenInUse) ? "Granted" : "Not granted"
        log("Location manager status changed: \(isGrantedDesc)", level: .high)
        
        guard status == .authorizedWhenInUse else { return }
        
        self.isGranted.accept(true)
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let last = locations.last else { return }
        
        log("Location updated", level: .high)
        
        let location = Location(
            latitude: last.coordinate.latitude,
            longitude: last.coordinate.longitude
        )
        
        self.locationsObserver.onNext(location)
    }
}
