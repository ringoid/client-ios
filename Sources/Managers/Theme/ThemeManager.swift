//
//  ThemeManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

enum ColorTheme: String
{
    case dark = "dark"
    case light = "light"
}

class ThemeManager
{
    var storageService: XStorageService?
    {
        didSet {
            self.storageService?.object("theme_key").subscribe(onNext:{ value in
                guard let themeValue = value as? String else { return }
                
                self.theme.accept(ColorTheme(rawValue: themeValue) ?? .dark)
            }).disposed(by: self.disposeBag)
        }
    }
    
    let theme: BehaviorRelay<ColorTheme> = BehaviorRelay<ColorTheme>(value: .dark)

    static let shared = ThemeManager()
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    private init()
    {
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.theme.asObservable().subscribe(onNext: { [weak self] value in
            guard let `self` = self else { return }
            
            self.storageService?.store(value.rawValue, key: "theme_key").subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
}
