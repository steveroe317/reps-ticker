//
//  ContentView.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 6/30/24.
//

import SwiftUI

struct ContentView: View {
    let fontSize: CGFloat = 16
    let imageFontSize: CGFloat = 36

    var body: some View {
        CoreContentView(imageFontSize: imageFontSize)
            .environment(\.font, Font.custom("SF Pro", size: fontSize))
    }
}

#Preview {
    ContentView()
}
