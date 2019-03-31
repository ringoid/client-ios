//
//  FileServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class FileServiceDefault: FileService
{
    fileprivate let fm = FileManager.default
    
    init()
    {
        self.checkSubdirectories()
    }
    
    func rm(_ path: FilePath)
    {
        guard path.type != .url, let url = path.url() else { return }
        
        try? self.fm.removeItem(at: url)
    }
    
    func reset()
    {
        try? self.fm.removeItem(at: URL(fileURLWithPath: temporaryDirectoryPath))
        try? self.fm.removeItem(at: URL(fileURLWithPath: documentsDirectoryPath))
        try? self.fm.removeItem(at: URL(fileURLWithPath: cacheDirectoryPath))
    
        self.checkSubdirectories()
    }
    
    // MARK: -
    
    fileprivate func checkSubdirectories()
    {
        if !fm.fileExists(atPath: documentsDirectoryPath)
        {
            try? fm.createDirectory(atPath: documentsDirectoryPath, withIntermediateDirectories: false, attributes: nil)
        }
        
        if !fm.fileExists(atPath: temporaryDirectoryPath)
        {
            try? fm.createDirectory(atPath: temporaryDirectoryPath, withIntermediateDirectories: false, attributes: nil)
        }
        
        if !fm.fileExists(atPath: cacheDirectoryPath)
        {
            try? fm.createDirectory(atPath: cacheDirectoryPath, withIntermediateDirectories: false, attributes: nil)
        }
    }
}
