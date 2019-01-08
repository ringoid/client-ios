//
//  ThemeManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

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
            _ = self.storageService?.object("theme_key").subscribe(onNext:{ value in
                guard let themeValue = value as? String else { return }
                
                self.theme = ColorTheme(rawValue: themeValue) ?? .dark
            })
        }
    }
    
    var theme: ColorTheme = .dark
    {
        didSet {
            _ = self.storageService?.store(self.theme.rawValue, key: "theme_key")
        }
    }
    
    static let shared = ThemeManager()
    
    private init() {}
}
