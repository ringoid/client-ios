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

enum Gender
{
    case male
    case female
}

struct AuthVMInput
{
    let profileManager: ProfileManager
    let apiService: ApiService
}

class AuthViewModel
{
    var gender: BehaviorRelay<Gender?> = BehaviorRelay(value: nil)
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
        return Observable<Void>.just(())
        //self.apiService.createProfile()
    }
}
