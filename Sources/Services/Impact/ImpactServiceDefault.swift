//
//  ImpactServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import DeviceKit
import AudioToolbox
import RxCocoa
import RxSwift

class ImpactServiceDefault: ImpactService
{
    var isEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    
    var isAvailable: Bool
    {
        return !Device.current.isOneOf([.iPhone4, .iPhone5, .iPhone5s, .iPhone6])
    }
    
    fileprivate var lightFeedback: UIImpactFeedbackGenerator?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init()
    {
        if self.isImpactGeneratorSupported() {
            self.lightFeedback = UIImpactFeedbackGenerator(style: .light)
            self.lightFeedback?.prepare()
        }
        
        self.loadSettings()
        self.setupBindings()
    }
    
    func perform(_ type: ImpactType)
    {
        guard self.isAvailable else { return }
        guard self.isEnabled.value else { return }
        
        if self.isImpactGeneratorSupported() {
            switch type {
            case .light: self.lightFeedback?.impactOccurred();
            default: break
            }
            
            return
        }
        
        switch type {
        case .light: AudioServicesPlaySystemSound(1519);
        default: break
        }
    }
    
    func reset()
    {
        self.isEnabled.accept(true)
        UserDefaults.standard.removeObject(forKey: "impact_service_is_enabled")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: -
    fileprivate func isImpactGeneratorSupported() -> Bool
    {
        let unsupportedDevices: [Device] = [.iPhone6s]
        let minSystemVersion: Double = 10
        
        let currentDevice = Device.current
        return !currentDevice.isOneOf(unsupportedDevices) && ((currentDevice.systemVersion as NSString?)?.doubleValue ?? 0.0) >= minSystemVersion
    }
    
    fileprivate func loadSettings()
    {
        guard let value = UserDefaults.standard.string(forKey: "impact_service_is_enabled") else {
            self.isEnabled.accept(true)
            
            return
        }
        
        self.isEnabled.accept(value == "true")
    }
    
    fileprivate func setupBindings()
    {
        self.isEnabled.subscribe(onNext: { state in
            let value = state ? "true" : "false"
            UserDefaults.standard.set(value, forKey: "impact_service_is_enabled")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
    }
}
