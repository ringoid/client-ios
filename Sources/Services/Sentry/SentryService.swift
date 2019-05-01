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
    case responseGeneralDelay = "Waiting for response longer than expected 2000 ms"
    case lastActionTimeError = "Last action time error"
    case somethingWentWrong = "Something Went Wrong"
    case waitingForResponseLLM = "Waiting for response from LMM longer than 2000 ms"
}

class SentryService
{
    static let shared = SentryService()
    
    var customerId: String? = nil
    
    private init() {}
    
    func setup()
    {
        do {
            #if STAGE
            Client.shared = try Client(dsn: "https://179c556658a3465d852019ffbb5aaac1@sentry.io/1387002")
            #else
            Client.shared = try Client(dsn: "https://66679f22e10c439ca88e34e68e11eabc@sentry.io/1417642")
            #endif
            try Client.shared?.startCrashHandler()
        } catch let error {
            log("Sentry error: \(error)", level: .high)
        }
    }
    
    func send(_ sentryEvent: SentryEvent, params: [String: String] = [:])
    {
        var tags: [String: String] = params
        
        if let customerId = self.customerId {
            tags["customerId"] = customerId
        }
        
        let event = Event(level: sentryEvent.level)
        event.message = sentryEvent.rawValue
        event.tags = tags
        Client.shared?.send(event: event, completion: nil)
    }
}

extension SentryEvent
{
    var level: SentrySeverity
    {
        switch self {
        case .repeatAfterDelay: return .warning
        case .internalError: return .error
        case .responseGeneralDelay: return .error
        case .lastActionTimeError: return .error
        case .somethingWentWrong: return .error
        case .waitingForResponseLLM: return .warning
        }
    }
}
