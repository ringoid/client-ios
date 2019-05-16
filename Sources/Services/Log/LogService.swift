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
import Fabric
import Crashlytics

func log(_ message: String, level: LogLevel)
{
    LogService.shared.log(message, level: level)
}

enum LogLevel
{
    case high;
    case medium;
    case low;
}

struct LogRecord
{
    let message: String
    let timestamp: Date
    let level: LogLevel
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
    
    func log(_ message: String, level: LogLevel)
    {
        self.records.accept(self.records.value + [LogRecord(
            message: message,
            timestamp: Date(),
            level: level
            )])
        
        CLSLogv("%@", getVaList([message]))
        
        #if DEBUG
        print("LOG(\(self.formatter.string(from: Date()))): \(message)")
        #endif
    }
    
    func clear()
    {
        self.records.accept([])
    }
    
    func asText() -> String
    {
        return self.records.value.reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
    
    func asClipboardText() -> String
    {
        return Array(self.records.value.suffix(30)).reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
    
    func asShortText() -> String
    {
        return Array(self.records.value.filter({ $0.level == .high }).suffix(6)).reduce(into: "", { (currentResult, record) in
            currentResult += self.formatter.string(from: record.timestamp) + ": " + record.message + "\n"
        })
    }
}
