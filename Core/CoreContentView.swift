//
//  CoreContentView.swift
//  Ticker
//
//  Created by Steve Roe on 7/1/24.
//

import AVFoundation
import SwiftUI

/// Common exercise counter view used by iPad, iPhone, and watch apps.
struct CoreContentView: View {
    @State private var repCounterActive = false
    @State private var repCount = 0
    @State var imageFontSize: CGFloat
    
    var body: some View {
        VStack {
            Image(systemName: "figure.core.training")
                .imageScale(.large)
                .foregroundStyle(.blue)
                .font(.custom("SF Pro", size: imageFontSize))
                .padding(.bottom)
            if repCounterActive {
                RepCounterView(counting: $repCounterActive, repCount: $repCount)
            } else {
                Text("Exercise Timer").padding()
                Text("Last Reps: \(repCount)")
                    .padding(.bottom)
                Button("Start") {
                    repCounterActive.toggle()
                }
            }
        }
    }
}

#Preview {
    CoreContentView(imageFontSize: 30)
        .environment(\.font, Font.custom("SF Pro", size: 36))
}
