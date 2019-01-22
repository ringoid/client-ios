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
