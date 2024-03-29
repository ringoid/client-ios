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
    var isDenied: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var initialTrigger: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var lastLocation: Location?
    {
        guard let coordinate = self.lm.location?.coordinate else { return nil }
        
        return Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    fileprivate var prevStatus: CLAuthorizationStatus? = nil
    fileprivate var locationsObserver: AnyObserver<Location>!
    fileprivate let lm: CLLocationManager = CLLocationManager()
    fileprivate var shouldTigger: Bool = false
    
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
        }).share()
        
        let status = CLLocationManager.authorizationStatus()
        self.lm.desiredAccuracy = status == .notDetermined ? 1000.0 : kCLLocationAccuracyBest
        self.lm.delegate = self
        self.isGranted.accept(status == .authorizedWhenInUse)
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
        defer {
            self.prevStatus = status
        }
        
        if let prevStatus = self.prevStatus {
            if prevStatus != status {
                self.shouldTigger = true
            }
        }
        
        let isGrantedDesc = (status == .authorizedWhenInUse) ? "Granted" : "Not granted"
        log("Location manager status changed: \(isGrantedDesc)", level: .high)
        
        self.isDenied.accept(status == .denied)    
        
        guard status == .authorizedWhenInUse else { return }
        
        self.isGranted.accept(true)
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let last = locations.last else { return }
        
        
        let location = Location(
            latitude: last.coordinate.latitude,
            longitude: last.coordinate.longitude
        )
        
        log("Location updated (lat: \(location.latitude), lon:\(location.longitude))", level: .high)
        
        self.locationsObserver.onNext(location)
        
        if self.shouldTigger {
            self.initialTrigger.accept(true)
            self.shouldTigger = false
            self.lm.desiredAccuracy = kCLLocationAccuracyBest
            self.lm.requestLocation()
        }
    }
}
