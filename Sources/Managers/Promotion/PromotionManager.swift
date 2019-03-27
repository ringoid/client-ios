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
import Branch

class PromotionManager
{
    let api: ApiService
    let branch: Branch
    
    init(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?, api: ApiService)
    {
        self.api = api
        self.branch = Branch.getInstance()
        self.branch.initSession(launchOptions: launchOptions) { [weak self] (params, error) in
            if let error = error {
                log("Branch error: \(error)", level: .high)
                
                return
            }
            
            guard let formattedParams = params as? [String: Any] else { return }
            
            self?.handle(formattedParams)
        }
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
        return self.valet.string(forKey: "referral_id")
    }
    
    func handleOpen(_ url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        let application = UIApplication.shared
        return self.branch.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func handleUserActivity(_ activity: NSUserActivity) -> Bool
    {
        self.branch.continue(activity)
        
        return true
    }
    
    // MARK: -
    
    fileprivate func handle(_ params: [String: Any])
    {
        print("BRANCH: \(params)")
    }
    
    fileprivate func send(_ referralCode: String) -> Observable<Void>
    {
        return self.api.claim(referralCode).do(onNext: { [weak self] _ in
            self?.storeReferral(referralCode)
        })
    }
    
    fileprivate func storeReferral(_ code: String)
    {
        self.valet.set(string: code, forKey: "referral_id")
    }
}
