//
//  TickerState.swift
//  Ticker
//
//  Created by Steve Roe on 11/1/24.
//

import Foundation

@Observable class IntentMessages {
    var startCounting: Int = 0
    var stopCounting: Int = 0
    
    static let shared = IntentMessages()
}
