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
        let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/fileservice/"
        if !fm.fileExists(atPath: documentsDirectoryPath)
        {
            try? fm.createDirectory(atPath: documentsDirectoryPath, withIntermediateDirectories: false, attributes: nil)
        }
    }
}
