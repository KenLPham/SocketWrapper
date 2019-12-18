//
//  SocketDispatchSource.swift
//  SocketWrapper
//
//  Created by Marco Masser on 2016-03-04.
//  Copyright © 2016 Objective Development. All rights reserved.
//

import Foundation

/// A wrapper around a `dispatch_source_t` that takes care of calling `dispatch_source_cancel()` in `deinit`.
///
/// This class is used for managing the lifetime of asynchronous callbacks in the `ReceiveAsyncSocketType`
/// and `AcceptAsyncSocketType` protocols.
class SocketDispatchSource {

    /// The managed dispatch source.
    private var dispatchSource: DispatchSourceRead?

    /// Creates an instance for the given `Socket`.
    ///
    /// The caller is responsible for keeping a reference to the new instance. If the instance is deinit'ed,
    /// the internal `dispatch_source_t` is cancelled and `eventHandler` won't be called anymore.
    ///
    /// - Parameter socket: The socket for which to create the dispatch source.
    /// - Parameter queue: The dispatch queue on which `eventHandler` should be called.
    /// - Parameter eventHandler: The closure to call whenever the dispatch source fires, that is:
    ///   - For a socket that can `receive()`, whenever the peer sent data and the socket is ready to be `received()` from.
    ///   - For a server socket, whenever a client has connected and its connection is ready to be `accept()`ed.
    init (socket: Socket, queue: DispatchQueue, eventHandler: @escaping () -> Void) {
		self.dispatchSource = DispatchSource.makeReadSource(fileDescriptor: socket.fileDescriptor, queue: queue)
		dispatchSource?.setEventHandler(handler: eventHandler)
		dispatchSource?.resume()
    }

    /// Cancels the dispatch source, therefore stopping calling the `eventHandler`.
    /// Called automatically in `deinit`.
    func cancel() {
		guard let source = self.dispatchSource else { return }
		source.cancel()
		self.dispatchSource = nil
    }
	
	deinit {
        cancel()
    }
}
