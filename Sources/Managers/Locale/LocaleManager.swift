//
//  LocaleManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 30/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation
import RxSwift

enum Language: String
{
    case english = "en"
}


class LocaleManager
{
    static let shared = LocaleManager()
    
    var storage: XStorageService?
    {
        didSet {
            self.loadCustomLocaleIfNeeded()
        }
    }
    
    fileprivate var bundle: Bundle!
    fileprivate var language: Language = .english
    {
        didSet {
            self.loadBundle(self.language)
        }
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    private init(){}
    
    func setLanguageManually(_ lang: Language)
    {
        self.language = lang
        self.storage?.store(lang.rawValue, key: "custom_locale").subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func loadCustomLocaleIfNeeded()
    {
        self.storage?.object("custom_locale").subscribe(
            onNext: { [weak self] obj in
                self?.language = Language(rawValue: String.create(obj)!) ?? .english
            }        , onError: { [weak self] _ in
                self?.language = Language(rawValue: NSLocale.preferredLanguages.first!) ?? .english
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func loadBundle(_ lang: Language)
    {
        guard let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj") else { return }
        self.bundle = Bundle(path: path)
    }
}

extension String
{
    func localized() -> String
    {
        return NSLocalizedString(self, tableName: nil, bundle: LocaleManager.shared.bundle, value: "", comment: "")
    }
}
