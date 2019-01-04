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
    let profileManager: ProfileManager
    let apiService: ApiService
}

class AuthViewModel
{
    var sex: BehaviorRelay<Sex?> = BehaviorRelay(value: nil)
    var birthYear: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    
    let profileManager: ProfileManager
    let apiService: ApiService
    
    init(_ input: AuthVMInput)
    {
        self.profileManager = input.profileManager
        self.apiService = input.apiService
    }
    
    func register() -> Observable<Void>
    {
        guard let year = self.birthYear.value, let sex = self.sex.value else {
            let error = createError("Not all fields are set", code: 0)
            
            return Observable<Void>.error(error)
        }
        
        return self.apiService.createProfile(year: year, sex: sex)
    }
}
