//
//  Phase.swift
//  Ticker
//
//  Created by Steve Roe on 7/1/24.
//

import Foundation

/// Phases of an exercise rep; engage, pause, return, pause.
@Observable class Phase {
    private var value = -3
    private var cycleCompleted = false
    
    func setPhase(phaseValue: Int) {
        value = phaseValue
    }
    
    func advance() {
        if value < 5 {
            value += 1
            cycleCompleted = false
        } else {
            value = 0
            cycleCompleted = true
        }
    }
    
    func atEngage() -> Bool {
        return value == 0
    }
    
    func atEngagePause() -> Bool {
        return value == 2
    }
    
    func atBack() -> Bool {
        return value == 3
    }
    
    func atBackPause () -> Bool {
        return value == 5
    }
    
    func CycleCompleted() -> Bool {
        return cycleCompleted
    }
    
    func label() -> String {
        switch value {
        case 0, 1: return "Engage"
        case 2: return "Pause"
        case 3, 4: return "Back"
        case 5: return "Pause"
        default: return "Ready \(-value)"
        }
    }
}
