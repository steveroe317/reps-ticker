//
//  RuntimeHost.swift
//  Ticker
//

/// Keeps the app running for the length of an activity, in whatever way the platform needs.
///
/// One host is held for a whole activity, never per segment.
protocol RuntimeHost: AnyObject {
    /// Seconds of "Ready" countdown before the first rep on this platform.
    var leadIn: Int { get }

    /// Starts keeping the app running.
    /// - Parameters:
    ///   - onReady: called once it is safe to start timing.
    ///   - onLost: called if the platform ends the runtime before `relinquish()`.
    func acquire(onReady: @escaping () -> Void, onLost: @escaping () -> Void)

    /// Stops keeping the app running. Callbacks from earlier `acquire` calls do not fire
    /// afterwards.
    func relinquish()
}
