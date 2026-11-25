//
//  WatchRepView.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

/// Exercise rep counter view.
///
/// Shows rep phase, rep count, and a stop button.
struct RepCounterView: View {
    @Binding var counting: Bool
    @Binding var repCount: Int
    @State var model = CounterSession()
    @State var intentMessages = IntentMessages.shared
    
    var body: some View {
        VStack {
            Text(model.phase.label())
            .padding()
            Text("Reps: \(model.count)")
            .padding(.bottom)
            Button("Stop") {
                endCounting()
            }
            .onChange(of: intentMessages.stopCounting) {
                endCounting()
            }
        }
    }
    
    func endCounting() {
        repCount = model.count
        model.stopCounting()
        counting = false
    }
}

#Preview {
//    @Previewable @State var counting = false
//    @Previewable @State var repCount = 0
//    return RepCounterView(counting: $counting, repCount: $repCount)
}
