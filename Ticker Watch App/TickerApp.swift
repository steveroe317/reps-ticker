//
//  TickerApp.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 6/30/24.
//

import AVFoundation
import SwiftUI

@main
struct Ticker_Watch_AppApp: App {

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .allowBluetoothA2DP)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
