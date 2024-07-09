//
//  RepCounter.swift
//  Ticker
//
//  Created by Steve Roe on 7/9/24.
//

import AVFoundation
import SwiftUI

struct RepCounter: View {
    @Binding var counting: Bool
    @Binding var repCount: Int
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var speaker = AVSpeechSynthesizer()
    @State var phase = Phase()
    @State private var count = 0
    @State private var running = false
    let soundEffects: SoundEffects = SoundEffects()
    
    var body: some View {
        VStack {
        Text(phase.label())
            .padding()
            .onReceive(timer) { time in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !running {
                        running = true
                        speaker.speak(AVSpeechUtterance(string: "ready"))
                    } else {
                        if phase.final {
                            count += 1
                        }
                        phase.advance()
                    }
                }
            }
        Text("Reps: \(count)")
            .padding(.bottom)
            .onChange(of: phase.oneStart) {
                speaker.speak(AVSpeechUtterance(string: String(count + 1)))
            }
            .onChange(of: phase.oneRest) {
                soundEffects.replay(name: "pause")
            }
            .onChange(of: phase.twoStart) {
                soundEffects.replay(name: "engage")
            }
            .onChange(of: phase.twoRest) {
                soundEffects.replay(name: "pause2")
            }
            
            Button("Stop") {
                counting.toggle()
                repCount = count
                stopTimer()
            }
        }
    }

    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    func stopTimer() {
        timer.upstream.connect().cancel()
    }
}

#Preview {
    @State var counting = true
    @State var repCount = 0
    return RepCounter(counting: $counting, repCount: $repCount)
}
