//
//  LogService.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

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
    
    let records: BehaviorRelay<[LogRecord]> = BehaviorRelay<[LogRecord]>(value: [])
    
    fileprivate let formatter = DateFormatter()
    
    private init()
    {
        self.formatter.dateFormat = "H:m:ss.SSS"
    }
    
    func log(_ message: String)
    {
        self.records.accept(self.records.value + [LogRecord(
            message: message,
            timestamp: Date()
            )])
        print("LOG(\(self.formatter.string(from: Date()))): \(message)")
    }
    
    func asText() -> String
    {
        return self.records.value.reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
    
    func asClipboardText() -> String
    {
        return Array(self.records.value.suffix(20)).reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
    
    func asShortText() -> String
    {
        return Array(self.records.value.suffix(4)).reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
}
