//
//  RepCounterView.swift
//  Ticker
//
//  Created by Steve Roe on 7/11/24.
//

import SwiftUI

/// Exercise rep counter view.
///
/// Shows rep phase, rep count, and a stop button.
struct RepCounterView: View {
    @Environment(ActivitySession.self) private var session
    @State private var intentMessages = IntentMessages.shared

    var body: some View {
        VStack {
            Text(session.label)
                .padding()
            Text("Reps: \(session.count)")
                .padding(.bottom)
            Button("Stop") {
                session.stop()
            }
            .onChange(of: intentMessages.stopCounting) {
                session.stop()
            }
        }
    }
}

#Preview {
    @Previewable @State var session = ActivitySession(host: PreviewRuntimeHost())
    RepCounterView()
        .environment(session)
        .onAppear { session.startReps() }
}
