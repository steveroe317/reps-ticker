//
//  StartCounting.swift
//  Ticker
//
//  Created by Steve Roe on 11/1/24.
//

import AppIntents
import Foundation

struct StartCounting: AppIntent {

    static var title: LocalizedStringResource = "Start Ticker Counting"
    static var description = IntentDescription("Opens RepTicker and starts counting reps, if not already counting")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let intentMessages = IntentMessages.shared
        
        intentMessages.startCounting += 1
        
        return .result()
    }
}
