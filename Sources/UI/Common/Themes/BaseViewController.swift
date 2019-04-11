//
//  BaseViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class BaseViewController: UIViewController
{
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.updateLocale()
        self.setupBindings()
    }
    
    // Override to update in runtime
    func updateLocale()
    {
        
    }
    
    func updateTheme()
    {
        
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        ThemeManager.shared.theme.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.updateTheme()
        }).disposed(by: self.disposeBag)
        
        LocaleManager.shared.language.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.updateLocale()
        }).disposed(by: self.disposeBag)
    }
}
