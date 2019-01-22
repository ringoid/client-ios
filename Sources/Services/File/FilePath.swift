//
//  FilePath.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum FileType
{
    case temporary
    case documents
    case cache
}

struct FilePath
{
    let filename: String
    let type: FileType
}

let temporaryDirectoryPath = NSTemporaryDirectory() + "/fileservice/"
let cacheDirectoryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/fileservice/"
let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/fileservice/"

extension FilePath
{
    func url() -> URL
    {
        var path: String = ""
        
        switch self.type {
        case .documents:
            path = documentsDirectoryPath
        case .temporary:
            path = temporaryDirectoryPath
        case .cache:
            path = cacheDirectoryPath
        }
        
        path += self.filename
        
        return URL(fileURLWithPath: path)
    }
}

extension FilePath
{
    static func unique(_ type: FileType) -> FilePath
    {
        return FilePath(filename: UUID().uuidString, type: type)
    }
}
