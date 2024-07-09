//
//  ContentView.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 6/30/24.
//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var speaker = AVSpeechSynthesizer()
    @State var activeToggle = false
    @State var phase = Phase()
    @State var repCount = 0
    let soundEffects: SoundEffects = SoundEffects()
    
    init () {
        stopTimer()
     }
    
    var body: some View {
        VStack {
            Image(systemName: "figure.core.training")
                .imageScale(.large)
                .foregroundStyle(.foreground)
                .font(.custom("SF Pro", size: 30))
                .padding(.bottom)
            if !activeToggle {
                Text("Exercise Timer").padding()
                Text("Last Reps: \(repCount)")
                    .padding()
            }
            if activeToggle {
                Text(phase.label())
                    .onReceive(timer) { time in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if phase.final {
                                repCount += 1
                            }
                            phase.advance()
                        }
                }
                .padding()
                Text("Reps: \(repCount)")
                    .padding()
                    .onChange(of: phase.oneStart) {
                        //soundEffects.replay(name: "engage")
                        speaker.speak(AVSpeechUtterance(string: String(repCount + 1)))
                    }
                    .onChange(of: phase.oneRest) {
                        soundEffects.replay(name: "pause")
                    }
                    .onChange(of: phase.twoStart) {
                        //soundEffects.replay(name: "return")
                        soundEffects.replay(name: "engage")
                    }
                    .onChange(of: phase.twoRest) {
                        soundEffects.replay(name: "pause2")
                    }
           }

            Button(activeToggle ? "Stop" : "Start") {
                activeToggle = !activeToggle
                if activeToggle {
                    phase.reset()
                    repCount = 0
                    startTimer()
                    speaker.speak(AVSpeechUtterance(string: "ready"))
                } else {
                    stopTimer()
                }
            }
        }
        .padding()
    }
    
    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    func stopTimer() {
        timer.upstream.connect().cancel()
    }
}

#Preview {
    ContentView()
}
