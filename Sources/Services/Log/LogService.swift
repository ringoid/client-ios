//
//  LogService.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

func log(_ message: String)
{
    LogService.shared.log(message)
}

struct LogRecord
{
    let message: String
    let timestamp: Date
}

class LogService
{
    static let shared = LogService()
    
    var records: [LogRecord] = []
    
    fileprivate let formatter = DateFormatter()
    
    private init()
    {
        self.formatter.dateFormat = "H:m:ss.SSSS"
    }
    
    func log(_ message: String)
    {
        self.records.append(LogRecord(
            message: message,
            timestamp: Date()
        ))
        
        print("LOG(\(self.formatter.string(from: Date()))): \(message)")
    }
    
    func asText() -> String
    {
        return self.records.reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
}
