//
//  CoreContentView.swift
//  Ticker
//
//  Created by Steve Roe on 7/1/24.
//

import AVFoundation
import SwiftUI

struct CoreContentView: View {
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var speaker = AVSpeechSynthesizer()
    @State var activeToggle = false
    @State var phase = Phase()
    @State var repCount = 0
    let soundEffects: SoundEffects = SoundEffects()
    let fontSize: CGFloat = 36
    let imageFontSize: CGFloat = 90

    init () {
        stopTimer()
     }
    
    var body: some View {
        ZStack {
            Color.brown.opacity(0.5).ignoresSafeArea()
            VStack {
                Image(systemName: "figure.core.training")
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                    .font(.custom("SF Pro", size: imageFontSize))
                if !activeToggle {
                    Text("Exercise Timer").padding()
                        .font(.custom("SF Pro", size: fontSize))
                    Text("Last Reps: \(repCount)")
                        .font(.custom("SF Pro", size: fontSize))
                        .padding(.bottom)
                }
                if activeToggle {
                    Text(phase.label())
                        .font(.custom("SF Pro", size: fontSize))
                        .padding()
                        .onReceive(timer) { time in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if phase.final {
                                    repCount += 1
                                }
                                phase.advance()
                            }
                        }
                    Text("Reps: \(repCount)")
                        .font(.custom("SF Pro", size: fontSize))
                        .padding(.bottom)
                        .onChange(of: phase.oneStart) {
                            speaker.speak(AVSpeechUtterance(string: String(repCount + 1)))
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
                .font(.custom("SF Pro", size: fontSize))
            }
            .padding()
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
    CoreContentView()
}
