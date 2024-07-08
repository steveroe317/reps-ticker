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
    @State var activeToggle = false
    @State var phase = Phase()
    @State var repCount = 0
    var engageSoundEffect: AVAudioPlayer? = nil
    var pauseSoundEffect: AVAudioPlayer? = nil
    var returnSoundEffect: AVAudioPlayer? = nil
    var pause2SoundEffect: AVAudioPlayer? = nil
    
    init () {
        stopTimer()
        engageSoundEffect = makeAudioPlayer(filename: "engage.wav")
        pauseSoundEffect = makeAudioPlayer(filename: "pause.wav")
        returnSoundEffect = makeAudioPlayer(filename: "return.wav")
        pause2SoundEffect = makeAudioPlayer(filename: "pause2.wav")
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
                        engageSoundEffect?.stop()
                        engageSoundEffect?.play()
                    }
                    .onChange(of: phase.oneRest) {
                        pauseSoundEffect?.stop()
                        pauseSoundEffect?.play()
                    }
                    .onChange(of: phase.twoStart) {
                        returnSoundEffect?.stop()
                        returnSoundEffect?.play()
                    }
                    .onChange(of: phase.twoRest) {
                        pause2SoundEffect?.stop()
                        pause2SoundEffect?.play()
                    }
           }

            Button(activeToggle ? "Stop" : "Start") {
                activeToggle = !activeToggle
                if activeToggle {
                    phase.reset()
                    repCount = 0
                    startTimer()
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
