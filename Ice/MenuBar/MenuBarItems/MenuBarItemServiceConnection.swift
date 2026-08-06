//
//  MenuBarItemServiceConnection.swift
//  Ice
//

import Foundation
import OSLog

// MARK: - MenuBarItemService.Connection

extension MenuBarItemService {
    /// A connection to the `MenuBarItemService` XPC service.
    final class Connection: Sendable {
        /// The shared connection.
        static let shared = Connection()

        /// The connection's underlying session.
        private let session: Session

        /// The connection's target queue.
        private let queue: DispatchQueue

        /// The connection's logger.
        private let logger: Logger

        /// Creates a new connection.
        private init() {
            let queue = DispatchQueue.targetingGlobal(
                label: "MenuBarItemService.Connection.queue",
                qos: .userInteractive,
                attributes: .concurrent
            )
            let logger = Logger(category: "MenuBarItemService.Connection")
            self.session = Session(queue: queue, logger: logger)
            self.queue = queue
            self.logger = logger
        }

        /// Starts the connection.
        func start() async {
            logger.debug("Starting MenuBarItemService connection")

            await withCheckedContinuation { continuation in
                guard let response = session.send(request: .start) else {
                    logger.error("Start request returned nil")
                    continuation.resume()
                    return
                }
                if case .start = response {
                    continuation.resume()
                } else {
                    logger.error("Start request returned invalid response \(String(describing: response))")
                    continuation.resume()
                }
            }
        }

        /// Returns the source process identifier for the given window.
        func sourcePID(for window: WindowInfo) async -> pid_t? {
            await withCheckedContinuation { continuation in
                guard let response = session.send(request: .sourcePID(window)) else {
                    logger.error("Source PID request returned nil")
                    continuation.resume(returning: nil)
                    return
                }
                if case .sourcePID(let pid) = response {
                    continuation.resume(returning: pid)
                } else {
                    logger.error("Source PID request returned invalid response \(String(describing: response))")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - MenuBarItemService.Session

extension MenuBarItemService {
    /// A wrapper around an XPC session.
    private final class Session: Sendable {
        /// A session's underlying storage.
        ///
        /// Unchecked: the non-Sendable `XPCSession` is reached only through
        /// ``Session/storage``, an `OSAllocatedUnfairLock` that serializes every
        /// access — `send(request:)`, `cancel(reason:)`, and the cancel handler
        /// installed in `getOrCreateSession(in:)`. The handler cannot deadlock
        /// against the lock scope that installs it: XPC submits session events to
        /// the target queue, which is set while the session is still inactive, so
        /// the handler never runs inline on a thread that already holds the lock.
        private struct Storage: @unchecked Sendable {
            var session: XPCSession?
        }

        /// The name of the XPC service the session connects to.
        private let name = MenuBarItemService.name

        /// Protected storage for the underlying XPC session.
        private let storage = OSAllocatedUnfairLock(initialState: Storage())

        /// The session's target queue.
        private let queue: DispatchQueue

        /// The session's logger.
        private let logger: Logger

        /// Creates a new session.
        init(queue: DispatchQueue, logger: Logger) {
            self.queue = queue
            self.logger = logger
        }

        deinit {
            cancel(reason: "Session deinitialized")
        }

        /// Returns the underlying XPC session, creating and activating one if needed.
        ///
        /// - Important: Callers must hold ``storage``'s lock.
        private func getOrCreateSession(in storage: inout Storage) throws -> XPCSession {
            if let session = storage.session {
                return session
            }
            let session = try XPCSession(xpcService: name, options: .inactive) { [weak self] error in
                guard let self else {
                    return
                }
                logger.warning("Session was cancelled with error \(error.localizedDescription)")
                self.storage.withLock { $0.session = nil }
            }
            // The `isFromSameTeam` requirement can only be satisfied when the
            // process has a Team Identifier. Ad-hoc/local development builds
            // have none, so skip the peer requirement for them.
            if CodeSigning.hasTeamIdentifier {
                session.setPeerRequirement(.isFromSameTeam())
            } else {
                logger.notice("Connecting without same-team peer requirement (no Team Identifier)")
            }
            session.setTargetQueue(queue)
            try session.activate()
            storage.session = session
            return session
        }

        /// Cancels the session.
        func cancel(reason: String) {
            storage.withLock { storage in
                guard let session = storage.session.take() else {
                    return
                }
                session.cancel(reason: reason)
            }
        }

        /// Sends the given request to the service and returns the response.
        func send(request: Request) -> Response? {
            storage.withLock { storage in
                do {
                    let session = try getOrCreateSession(in: &storage)
                    let reply = try session.sendSync(request)
                    return try reply.decode(as: Response.self)
                } catch {
                    logger.error("Session failed with error \(error)")
                    return nil
                }
            }
        }
    }
}
