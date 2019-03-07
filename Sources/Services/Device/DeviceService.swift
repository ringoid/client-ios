//
//  DeviceService.swift
//  ringoid
//
//  Created by Victor Sukochev on 30/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

protocol DeviceService
{
    var photoResolution: String { get }
    var deviceName: String { get }
}
