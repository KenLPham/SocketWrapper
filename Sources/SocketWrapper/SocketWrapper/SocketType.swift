//
//  CommonSocketProtocols.swift
//  SocketWrapper
//
//  Created by Marco Masser on 2016-03-04.
//  Copyright © 2016 Objective Development. All rights reserved.
//

import Darwin

/// Represents the base type for more specialized socket types.
protocol SocketType {

    /// The underlying `Socket` that is used for various methods of the sub types, e.g. `send()`, `receive()`. etc.
    var socket: Socket { get }

    /// Called whenever `close()` was called on the socket.
    /// This is an override point for implementers. The default implementation does nothing.
    func didClose()

}


// Common methods.
extension SocketType {

    /// Closes the socket and calls `didClose()`.
    func close() throws {
        defer {
            didClose()
        }
        try socket.close()
    }

    func didClose() {
        // Empty default implementation
    }
	
	func add (membership request: UnsafePointer<ip_mreq>) {
		socket.add(membership: request)
	}
	
	func drop (membership request: UnsafePointer<ip_mreq>) {
		socket.drop(membership: request)
	}

    /// Pass through to `Socket`'s `socket` subscript.
	subscript (socket option: Int32) -> Int32 {
        get {
            return socket[socket: option]
        }
        nonmutating set {
            socket[socket: option] = newValue
        }
    }

	/// Pass through to `Socket`'s `ip` subscript.
	subscript (ip option: Int32) -> Int32 {
		get {
            return socket[ip: option]
        }
        nonmutating set {
            socket[ip: option] = newValue
        }
	}
}
