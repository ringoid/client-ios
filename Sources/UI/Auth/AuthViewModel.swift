//
//  AuthViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum Sex: String
{
    case male = "male"
    case female = "female"
}

struct AuthVMInput
{
    let apiService: ApiService
    let settingsManager: SettingsManager
    let promotionManager: PromotionManager
    let locationManager: LocationManager
    let profileManager: UserProfileManager
}

class AuthViewModel
{
    var sex: BehaviorRelay<Sex?> = BehaviorRelay(value: nil)
    var birthYear: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    
    let apiService: ApiService
    let settingsManager: SettingsManager
    let promotionManager: PromotionManager
    let locationManager: LocationManager
    let profileManager: UserProfileManager
    
    init(_ input: AuthVMInput)
    {
        self.apiService = input.apiService
        self.settingsManager = input.settingsManager
        self.promotionManager = input.promotionManager
        self.locationManager = input.locationManager
        self.profileManager = input.profileManager
    }
    
    func register() -> Observable<Void>
    {
        guard let year = self.birthYear.value, let sex = self.sex.value else {
            let error = createError("Not all fields are set", type: .visible)
            
            return Observable<Void>.error(error)
        }
        
        let privateKey = self.promotionManager.privateKey
        let referralCode = self.promotionManager.referralCode
        
        return self.apiService.createProfile(year: year, sex: sex, privateKey: privateKey, referralCode: referralCode).do(onNext: { [weak self] _ in
            AnalyticsManager.shared.send(.profileCreated(year, sex.rawValue))
            self?.settingsManager.updateRemoteSettings()
            self?.settingsManager.updatePushToken()
            self?.locationManager.sendLastLocationIfAvailable()
            self?.profileManager.createProfile()
            self?.profileManager.gender.accept(sex)
            self?.profileManager.yob.accept(year)
            self?.profileManager.creationDate.accept(Date())
        })
    }
    
    func switchTheme()
    {
        let theme = ThemeManager.shared.theme.value
        
        switch theme {
        case .dark: ThemeManager.shared.theme.accept(.light)
        case .light: ThemeManager.shared.theme.accept(.dark)
        }
    }
}

extension Sex
{
    func opposite() -> Sex
    {
        return self == .male ? .female : .male
    }
}
