//
//  ContentView.swift
//  Ticker
//
//  Created by Steve Roe on 6/30/24.
//

import SwiftUI

struct ContentView: View {
    let fontSize: CGFloat = 36
    let imageFontSize: CGFloat = 90

    var body: some View {
        ZStack {
            Color.brown.opacity(0.5).ignoresSafeArea()
            CoreContentView(imageFontSize: imageFontSize)
                .environment(\.font, Font.custom("SF Pro", size: fontSize))
        }
    }
}

#Preview {
    ContentView()
}
