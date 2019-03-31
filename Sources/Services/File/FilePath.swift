//
//  FilePath.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum FileType: Int
{
    case url = 0
    case temporary = 1
    case documents = 2
    case cache = 3
}

struct FilePath
{
    let filename: String
    let type: FileType
}

let temporaryDirectoryPath = NSTemporaryDirectory() + "fileservice/"
let cacheDirectoryPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!.path + "/fileservice/"
let documentsDirectoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.path + "/fileservice/"

extension FilePath
{
    func url() -> URL?
    {
        switch self.type {
        case .url:
            return URL(string: self.filename)
        case .documents:
            return URL(fileURLWithPath: documentsDirectoryPath + self.filename)
        case .temporary:
            return URL(fileURLWithPath: temporaryDirectoryPath + self.filename)
        case .cache:
            return URL(fileURLWithPath: cacheDirectoryPath + self.filename)
        }
    }
}

extension FilePath
{
    static func unique(_ type: FileType) -> FilePath
    {
        return FilePath(filename: UUID().uuidString, type: type)
    }
}
