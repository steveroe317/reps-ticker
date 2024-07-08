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
    @State var activeToggle = false
    @State var phase = Phase()
    @State var repCount = 0
    var engageSoundEffect: AVAudioPlayer? = nil
    var pauseSoundEffect: AVAudioPlayer? = nil
    var returnSoundEffect: AVAudioPlayer? = nil
    var pause2SoundEffect: AVAudioPlayer? = nil
    let fontSize: CGFloat = 36
    let imageFontSize: CGFloat = 90

    init () {
        stopTimer()
        engageSoundEffect = makeAudioPlayer(filename: "engage.wav")
        pauseSoundEffect = makeAudioPlayer(filename: "pause.wav")
        returnSoundEffect = makeAudioPlayer(filename: "return.wav")
        pause2SoundEffect = makeAudioPlayer(filename: "pause2.wav")
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
