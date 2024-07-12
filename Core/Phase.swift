//
//  Phase.swift
//  Ticker
//
//  Created by Steve Roe on 7/1/24.
//

import Foundation

@Observable class Phase {
    var phase = -3
    var final = false
    var oneStart = 0
    var oneRest = 0
    var twoStart = 0
    var twoRest = 0
    var completed = 0
    
    func advance() {
        // Advance phase. Publish a complete event on roll over.
        if phase < 5 {
            phase += 1
        } else {
            phase = 0
            completed += 1
        }
        final = (phase == 5)

        // Publish start and rest events.
        if phase == 0 {
            oneStart += 1
        } else if phase == 2 {
            oneRest += 1
        } else if phase == 3 {
            twoStart += 1
        } else if phase == 5 {
            twoRest += 1
        }
    }
    
    // TODO: use at*() functions in advance()
    
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
