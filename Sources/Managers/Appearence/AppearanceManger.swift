//
//  AppearanceManger.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AppearanceManger
{
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init()
    {
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        ThemeManager.shared.theme.asObservable().subscribe(onNext: { [weak self] theme in
            //self?.updateTableViews(theme)
            //self?.updateButtons(theme)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateTableViews(_ theme: ColorTheme)
    {
        let darkThemeSeparatorColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        UITableView.appearance().separatorColor = (theme == .dark) ? darkThemeSeparatorColor : .black
    }
    
    fileprivate func updateButtons(_ theme: ColorTheme)
    {
        UIButton.appearance().tintColor = .purple
    }
}
