//
//  IOSRuntimeHost.swift
//  Ticker
//
//  Created by Steve Roe on 7/11/24.
//

/// The iOS and iPadOS runtime host.
///
/// The `audio` background mode keeps the app running while cues play, so there is nothing to
/// acquire and timing can start at once.
final class IOSRuntimeHost: RuntimeHost {
    let leadIn = 3

    func acquire(onReady: @escaping () -> Void, onLost: @escaping () -> Void) {
        onReady()
    }

    func relinquish() {}
}
