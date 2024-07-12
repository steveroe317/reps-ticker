//
//  WatchRepView.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 7/11/24.
//

import AVFoundation
import SwiftUI

struct WatchRepView: View {
    @Binding var counting: Bool
    @Binding var repCount: Int
    @State var model = ContentModel()

    var body: some View {
        VStack {
            Text(model.phase.label())
            .padding()
            Text("Reps: \(model.count)")
            .padding(.bottom)
            Button("Stop") {
                counting.toggle()
                repCount = model.count
                model.stopCounting()
            }
        }
    }
}

#Preview {
    @State var counting = true
    @State var repCount = 0
    return WatchRepView(counting: $counting, repCount: $repCount)
}
