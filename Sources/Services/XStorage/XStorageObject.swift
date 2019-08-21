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

extension Date: XStorageObject
{
    func storableObject() -> Any
    {
        return String(Int(self.timeIntervalSince1970 * 1000.0))
    }
    
    static func create(_ from: Any) -> Date?
    {
        guard let str = (from as? String), let interval = Int(str) else { return nil }
        
        return Date(timeIntervalSince1970: Double(interval) / 1000.0)
    }
        
}

extension Array: XStorageObject where Element == String
{
    func storableObject() -> Any
    {
        return self.reduce(into:"", { (currentResult, element) in
            if currentResult.count != 0 {
                currentResult += "," + element
            } else {
                currentResult += element
            }
        })
    }
    
    static func create(_ from: Any) -> [String]?
    {
        return (from as? String)?.components(separatedBy: CharacterSet(charactersIn: ","))
    }
}

extension Set: XStorageObject where Element == String
{
    func storableObject() -> Any
    {
        return self.reduce(into:"", { (currentResult, element) in
            if currentResult.count != 0 {
                currentResult += "," + element
            } else {
                currentResult += element
            }
        })
    }
    
    static func create(_ from: Any) -> Set<String>?
    {
        guard let fromStr = from as? String, fromStr.count > 0 else { return nil }
        guard let components = (from as? String)?.components(separatedBy: CharacterSet(charactersIn: ",")) else { return nil }
        
        return Set<String>(components)
    }
}
