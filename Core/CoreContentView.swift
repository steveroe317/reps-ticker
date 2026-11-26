//
//  CoreContentView.swift
//  Ticker
//
//  Created by Steve Roe on 7/1/24.
//

import SwiftUI

/// Common exercise counter view used by iPad, iPhone, and watch apps.
struct CoreContentView: View {
    @Environment(ActivitySession.self) private var session
    @State var imageFontSize: CGFloat
    @State private var intentMessages = IntentMessages.shared

    var body: some View {
        VStack {
            Image(systemName: "figure.core.training")
                .imageScale(.large)
                .foregroundStyle(.blue)
                .font(.custom("SF Pro", size: imageFontSize))
                .padding(.bottom)
            if session.isActive {
                RepCounterView()
            } else {
                Text("Exercise Timer").padding()
                Text("Last Reps: \(session.lastReps)")
                    .padding(.bottom)
                Button("Start") {
                    session.startReps()
                }
                .onChange(of: intentMessages.startCounting) {
                    session.startReps()
                }
            }
        }
    }
}

#Preview {
    CoreContentView(imageFontSize: 90)
        .environment(\.font, Font.custom("SF Pro", size: 36))
        .environment(ActivitySession(host: PreviewRuntimeHost()))
}
