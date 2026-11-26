//
//  TickerApp.swift
//  Ticker
//
//  Created by Steve Roe on 6/30/24.
//

import AVFoundation
import SwiftUI

@main
struct TickerApp: App {
    @State private var session: ActivitySession

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .allowBluetoothA2DP)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error.localizedDescription)
        }
        // Created once the audio session is configured.
        _session = State(initialValue: ActivitySession(host: IOSRuntimeHost()))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
    }
}
