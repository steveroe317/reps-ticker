//
//  FakeRuntimeHost.swift
//  TickerTests
//

@testable import Ticker

/// A runtime host that records calls and fires its callbacks only when a test asks.
@MainActor
final class FakeRuntimeHost: RuntimeHost {
    let leadIn = 3
    private(set) var acquireCount = 0
    private(set) var relinquishCount = 0
    private var readyCallbacks: [() -> Void] = []
    private var lostCallbacks: [() -> Void] = []

    func acquire(onReady: @escaping () -> Void, onLost: @escaping () -> Void) {
        acquireCount += 1
        readyCallbacks.append(onReady)
        lostCallbacks.append(onLost)
    }

    func relinquish() {
        relinquishCount += 1
    }

    /// Fires `onLost` from the given `acquire` call, counting from 0; defaults to the latest.
    func loseRuntime(fromAcquire index: Int? = nil) {
        lostCallbacks[index ?? lostCallbacks.count - 1]()
    }
}
