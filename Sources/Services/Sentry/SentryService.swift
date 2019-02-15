//
//  SentryService.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Sentry

enum SentryEvent: String
{
    case repeatAfterDelay = "Repeat after delay"
    case internalError = "Internal Server Error"
    case responseGeneralDelay = "Waiting for response longer than expected"
}

class SentryService
{
    static let shared = SentryService()
    
    private init() {}
    
    func setup()
    {
        do {
            Client.shared = try Client(dsn: "https://179c556658a3465d852019ffbb5aaac1@sentry.io/1387002")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("Sentry error: \(error)")
        }
    }
    
    func send(_ sentryEvent: SentryEvent)
    {
        let event = Event(level: sentryEvent.level)
        event.message = sentryEvent.rawValue
        Client.shared?.send(event: event, completion: nil)
    }
}

extension SentryEvent
{
    var level: SentrySeverity
    {
        switch self {
        case .repeatAfterDelay: return .error
        case .internalError: return .error
        case .responseGeneralDelay: return .warning
            
        }
    }
}
