//
//  ThemeViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class ThemeViewController: UIViewController
{
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        ThemeManager.shared.theme.asObservable().subscribeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.view.backgroundColor = BackgroundColor().uiColor()
        }).disposed(by: self.disposeBag)
    }
}
