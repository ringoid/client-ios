//
//  LocaleManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 30/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum Language: String
{
    case english = "en"
}


class LocaleManager
{
    static let shared = LocaleManager()
    
    let language: BehaviorRelay<Language> = BehaviorRelay<Language>(value: .english)
    var storage: XStorageService?
    {
        didSet {
            self.loadCustomLocaleIfNeeded()
        }
    }
    
    fileprivate var bundle: Bundle!
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    private init()
    {
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.language.asObservable().subscribe(onNext: { [weak self] lang in
            self?.storeLanguage(lang)
            self?.loadBundle(lang)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func loadCustomLocaleIfNeeded()
    {
        self.storage?.object("custom_locale").subscribe(
            onNext: { [weak self] obj in
                let lang = Language(rawValue: String.create(obj)!) ?? .english
                self?.language.accept(lang)
            }, onError: { [weak self] _ in
                let lang = Language(rawValue: NSLocale.preferredLanguages.first!) ?? .english
                self?.language.accept(lang)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func storeLanguage(_ lang: Language)
    {
        self.storage?.store(lang.rawValue, key: "custom_locale").subscribe().disposed(by: self.disposeBag)
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
