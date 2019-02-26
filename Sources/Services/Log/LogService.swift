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
    
    private init() {}
    
    func log(_ message: String)
    {
        self.records.append(LogRecord(
            message: message,
            timestamp: Date()
        ))
        
        print("LOG: \(message)")
    }
    
    func asText() -> String
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        
        return self.records.reduce(into: "", { (currentResult, record) in
            currentResult += formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
}
