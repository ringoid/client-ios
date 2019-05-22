//
//  SettingsNotificationsCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 01/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingsNotificationsCell: BaseTableViewCell
{
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var pushLabel: UILabel!

    override func updateLocale()
    {
        self.pushLabel.text = "settings_push".localized()
    }
    
    override func updateTheme()
    {
        self.pushLabel.textColor = ContentColor().uiColor()
    }
}
