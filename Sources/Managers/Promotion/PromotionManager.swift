//
//  PromotionManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Valet
import RxSwift
import RxCocoa

class PromotionManager
{
    let api: ApiService
    
    init(_ api: ApiService)
    {
        self.api = api
    }
    
    fileprivate let valet = Valet.valet(with: Identifier(nonEmpty: "Ringoid")!, accessibility: .whenUnlocked)
    
    var privateKey: String
    {
        guard let key = self.valet.string(forKey: "private_key") else {
            let key = UUID().uuidString
            self.valet.set(string: key, forKey: "private_key")
            
            return key
        }
        
        return key
    }
    
    var referralCode: String?
    {
        return UserDefaults.standard.string(forKey: "referral_code")
    }
    
    func send(_ referralCode: String) -> Observable<Void>
    {
        return self.api.claim(referralCode).do(onNext: { [weak self] _ in
            self?.storeReferral(referralCode)
        })
    }
    
    // MARK: -
    
    fileprivate func storeReferral(_ code: String)
    {
        UserDefaults.standard.setValue(code, forKey: "referral_code")
        UserDefaults.standard.synchronize()
    }
}
