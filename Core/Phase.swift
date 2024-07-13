//
//  Phase.swift
//  Ticker
//
//  Created by Steve Roe on 7/1/24.
//

import Foundation

@Observable class Phase {
    var phase = -3
    private var cycleCompleted = false
    
    func advance() {
        if phase < 5 {
            phase += 1
            cycleCompleted = false
        } else {
            phase = 0
            cycleCompleted = true
        }
    }
    
    func atEngage() -> Bool {
        return phase == 0
    }
    
    func atEngagePause() -> Bool {
        return phase == 2
    }
    
    func atBack() -> Bool {
        return phase == 3
    }
    
    func atBackPause () -> Bool {
        return phase == 5
    }
    
    func CycleCompleted() -> Bool {
        return cycleCompleted
    }
    
    func label() -> String {
        switch phase {
        case 0, 1: return "Engage"
        case 2: return "Pause"
        case 3, 4: return "Back"
        case 5: return "Pause"
        default: return "Ready \(-phase)"
        }
    }
}
