//
//  StopCounting.swift
//  Ticker
//
//  Created by Steve Roe on 11/1/24.
//

import AppIntents
import Foundation

struct StopCounting: AppIntent {

    static let title: LocalizedStringResource = "Stop Ticker Counting"
    static let description = IntentDescription("Stops RepTicker counting reps, if already counting")
    static let openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let intentMessages = IntentMessages.shared
        
        intentMessages.stopCounting += 1
        
        return .result()
    }
}
