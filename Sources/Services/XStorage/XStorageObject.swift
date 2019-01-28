//
//  XStorageObject.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

protocol XStorageObject
{
    func storableObject() -> Any
    static func create(_ from: Any) -> Self?
}

// MARK: - String

extension String: XStorageObject
{
    func storableObject() -> Any
    {
        return self
    }
    
    static func create(_ from: Any) -> String?
    {
        return from as? String
    }
}

// MARK: - Bool

extension Bool: XStorageObject
{
    func storableObject() -> Any
    {
        return self ? "true" : "false"
    }
    
    static func create(_ from: Any) -> Bool?
    {
        return (from as? String) == "true"
    }
}
