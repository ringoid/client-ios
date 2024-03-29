//
//  Colors.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ThemeColor
{
    func uiColor() -> UIColor
    {
        return .clear
    }
}

class BackgroundColor: ThemeColor
{
    override func uiColor() -> UIColor
    {
        switch ThemeManager.shared.theme.value {
        case .dark: return UIColor(red: 21.0 / 255.0, green: 25.0 / 255.0, blue: 29.0 / 255.0, alpha: 1.0)
        case .light: return .white
        }
    }
}

class ContentColor: ThemeColor
{
    override func uiColor() -> UIColor
    {
        switch ThemeManager.shared.theme.value {
        case .dark: return .white
        case .light: return UIColor(red: 21.0 / 255.0, green: 25.0 / 255.0, blue: 29.0 / 255.0, alpha: 1.0)
        }
    }
}

class SecondContentColor: ThemeColor
{
    override func uiColor() -> UIColor
    {
        switch ThemeManager.shared.theme.value {
        case .dark: return UIColor(red: 186.0 / 255.0, green: 186.0 / 255.0, blue: 186.0 / 255.0, alpha: 1.0)
        case .light: return UIColor(red: 21.0 / 255.0, green: 25.0 / 255.0, blue: 29.0 / 255.0, alpha: 1.0)
        }
    }
}

class ThirdContentColor: ThemeColor
{
    override func uiColor() -> UIColor
    {
        switch ThemeManager.shared.theme.value {
        case .dark: return UIColor(red: 138.0 / 255.0, green: 138.0 / 255.0, blue: 138.0 / 255.0, alpha: 1.0)
        case .light: return UIColor(red: 21.0 / 255.0, green: 25.0 / 255.0, blue: 29.0 / 255.0, alpha: 1.0)
        }
    }
}
