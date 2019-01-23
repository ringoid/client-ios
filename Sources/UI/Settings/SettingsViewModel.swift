//
//  SettingsViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class SettingsViewModel
{
    var theme: BehaviorRelay<ColorTheme> {
        return ThemeManager.shared.theme
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init() {}
}
