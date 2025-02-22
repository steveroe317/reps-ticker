//
//  ContentModel.swift
//  Ticker
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

/// Times an exercise set reps with auditory cues and counts.
///
/// This class is different in iOS/ipadOS and watchOS due to differences in background task
/// task handling.
@Observable
final class CounterSession: CounterSessionBase {
    
    override init () {
        super.init()
        startCounting()
    }
    
    deinit {
        stopCounting()
    }
    
    private func startCounting() {
        guard sharedTimer.timer == nil else {
            return
        }
        issueReadyAnnouncement()
        sharedTimer.timer = makeCounterTimer()
        if sharedTimer.timer != nil {
            RunLoop.main.add(sharedTimer.timer!, forMode: .common)
        }
    }
    
    func stopCounting() {
        sharedTimer.timer?.invalidate()
        sharedTimer.timer = nil
        issueCompleteAnnouncement()
    }
}
