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
    var theme: BehaviorRelay<ColorTheme> = BehaviorRelay<ColorTheme>(value: ThemeManager.shared.theme)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init()
    {
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.theme.asObservable().subscribe(onNext:{ value in
            ThemeManager.shared.theme = value
        }).disposed(by: self.disposeBag)
    }
}
