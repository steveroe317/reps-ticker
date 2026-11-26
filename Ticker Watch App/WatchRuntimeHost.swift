//
//  WatchRuntimeHost.swift
//  Ticker Watch App
//
//  Created by Steve Roe on 7/11/24.
//

import WatchKit

/// The watchOS runtime host.
///
/// Holds a `WKExtendedRuntimeSession` for the length of an activity, so watchOS keeps the app
/// running when the wrist is lowered.
final class WatchRuntimeHost: NSObject, RuntimeHost {
    /// Longer than on iOS, to give the speech synthesizer time to start up.
    let leadIn = 5

    private var session: WKExtendedRuntimeSession?
    private var onReady: (() -> Void)?
    private var onLost: (() -> Void)?

    func acquire(onReady: @escaping () -> Void, onLost: @escaping () -> Void) {
        relinquish()
        self.onReady = onReady
        self.onLost = onLost
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        self.session = session
        session.start()
    }

    func relinquish() {
        let session = session
        clear()
        session?.invalidate()
    }

    private func clear() {
        session = nil
        onReady = nil
        onLost = nil
    }
}

extension WatchRuntimeHost: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        guard extendedRuntimeSession === session else { return }
        onReady?()
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    }

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: (any Error)?
    ) {
        // Sessions ended by `relinquish()` were already cleared, so only an invalidation the app
        // did not ask for gets this far.
        guard extendedRuntimeSession === session else { return }
        let onLost = onLost
        clear()
        onLost?()
    }
}
