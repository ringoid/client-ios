//
//  BaseTableViewCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 06/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BaseTableViewCell: UITableViewCell
{
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
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
        LocaleManager.shared.language.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.updateLocale()
        }).disposed(by: self.disposeBag)
        
        ThemeManager.shared.theme.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.updateTheme()
        }).disposed(by: self.disposeBag)
    }
}
