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

class ImpactServiceDefault: ImpactService
{
    fileprivate var lightFeedback: UIImpactFeedbackGenerator?
    
    init()
    {
        if self.isImpactGeneratorSupported() {
            self.lightFeedback = UIImpactFeedbackGenerator(style: .light)
            self.lightFeedback?.prepare()
        }
    }
    
    func perform(_ type: ImpactType)
    {
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
    
    // MARK: -
    fileprivate func isImpactGeneratorSupported() -> Bool
    {
        let unsupportedDevices: [Device] = [.iPhone4, .iPhone5, .iPhone5s, .iPhone6, .iPhone6s]
        let minSystemVersion: Double = 10
        
        let currentDevice = Device()
        return !currentDevice.isOneOf(unsupportedDevices) && ((currentDevice.systemVersion as NSString).doubleValue) >= minSystemVersion
    }
}
