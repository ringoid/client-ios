//
//  SettingsLocaleViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class SettingsLocaleViewModel
{
    var locales: [Language]
    {
        return [
            .english
        ]
    }
    
    var locale: BehaviorRelay<Language>
    {
        return LocaleManager.shared.language        
    }
}
