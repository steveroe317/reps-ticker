//
//  TickerModel.swift
//  Ticker
//
//  Created by Steve Roe on 11/2/24.
//

import Foundation

@Observable class TimerSingleton {
    static let shared = TimerSingleton()
    var timer: Timer?
    
    private init() {}
}
