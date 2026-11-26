//
//  PreviewRuntimeHost.swift
//  Ticker
//

/// A runtime host for SwiftUI previews: ready at once, and holds nothing.
final class PreviewRuntimeHost: RuntimeHost {
    let leadIn = 3

    func acquire(onReady: @escaping () -> Void, onLost: @escaping () -> Void) {
        onReady()
    }

    func relinquish() {}
}
