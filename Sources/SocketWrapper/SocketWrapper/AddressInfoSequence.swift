//
//  AddressInfoSequence.swift
//  SocketWrapper
//
//  Created by Marco Masser on 2016-03-04.
//  Copyright © 2016 Objective Development. All rights reserved.
//

import Darwin

/// A wrapper around a `addrinfo` linked list.
///
/// - Important: When iterating over an `AddressInfoSequence` using its `SequenceType` conformance, the `addrinfo`
///   struct's internal pointers are only valid as long as the `GeneratorType` returned by `generate` is alive.
struct AddressInfoSequence {

    /// An internal storage that is used by `AddressInfoSequence` and its `SequenceType` implementation.
	class Storage {

        /// The internal pointer to the head of the linked list.
        ///
        /// - Important: This pointer and the whole linked list - including all the `addrinfo`'s
        ///              internal pointers - are only valid as long as `self` is referenced.
		let _addrInfoPointer: UnsafeMutablePointer<addrinfo>

        /// Creates an instance with an existing `UnsafeMutablePointer<addrinfo>`, taking ownership of it.
        init(addrInfoPointer: UnsafeMutablePointer<addrinfo>) {
            _addrInfoPointer = addrInfoPointer
        }

        deinit {
            freeaddrinfo(_addrInfoPointer)
        }
        
    }

    /// The internal storage for the `addrinfo` linked list.
	let _addrInfoStorage: Storage

    /// Creates an instance intended for a server socket for the given `port` that will be used with `bind()`.
    ///
    /// - parameter family: Default: `AF_UNSPEC`, i.e. IP4 or IP6.
    /// - parameter socketType: Default: `SOCK_STREAM`, i.e. a TCP socket.
    /// - parameter flags: Default: `AI_PASSIVE`, i.e. set the IP address of the resulting `sockaddr` to `INADDR_ANY` (IPv4) or `IN6ADDR_ANY_INIT` (IPv6).
	/// - parameter protocol: Default: `IPPROTO_IP`,
	init (forBindingTo port: String?, family: Int32 = AF_UNSPEC, socketType: Int32 = SOCK_STREAM, flags: Int32 = AI_PASSIVE, protocol proto: Int32 = IPPROTO_TCP) throws {
		try self.init(host: nil, port: port, family: family, socketType: socketType, flags: flags, protocol: proto)
    }

    /// Creates an instance intended for a client socket for the given `host` and `port` that will be used with `connect()`.
    ///
    /// - parameter family: Default: `AF_UNSPEC`, i.e. IP4 or IP6.
    /// - parameter socketType: Default: `SOCK_STREAM`, i.e. a TCP socket.
    /// - parameter flags: Default: `AI_DEFAULT` (= `AI_V4MAPPED_CFG | AI_ADDRCONFIG`).
	init (forConnectingTo host: String?, port: String, family: Int32 = AF_UNSPEC, socketType: Int32 = SOCK_STREAM, flags: Int32 = AI_V4MAPPED_CFG | AI_ADDRCONFIG, protocol proto: Int32 = IPPROTO_TCP) throws {
		try self.init(host: host, port: port, family: family, socketType: socketType, flags: flags, protocol: proto)
    }

    /// Creates an instance for the given `host` and/or `port`.
    ///
    /// - parameter family: For example `AF_UNSPEC`, i.e. IP4 or IP6.
    /// - parameter socketType: For example `SOCK_STREAM`, i.e. a TCP socket.
    /// - parameter flags: For example `AI_DEFAULT`.
	private init (host: String?, port: String?, family: Int32, socketType: Int32, flags: Int32, protocol proto: Int32) throws {
        var hints = addrinfo();
        hints.ai_family = family
        hints.ai_socktype = socketType
        hints.ai_flags = flags
		hints.ai_protocol = proto
		
        try self.init(host: host, port: port, hints: &hints)
    }

    /// Creates an instance by calling `getaddrinfo()` with the given arguments.
    ///
    /// Throws an error either if `getaddrinfo` failed, or if it returned an empty list. Therefore, if this initializer doesn't throw,
    /// the created instance is guaranteed to have at least one `addrinfo`.
    ///
    /// - Parameter host: The hostname or IP address to resolve. Pass `nil` when resolving addresses for a server socket.
    /// - Parameter port: The port or service name to resolve, e.g. "80" or "http". Pass `nil` when resolving an address
    ///   for a protocol that does not use ports, e.g. ICMP.
    /// - Parameter hints: A pointer to an `addrinfo` struct that is used as hints. This allows specifying things like
    ///   the protocol family, socket type, or protocol. May be `nil`.
    ///
    /// - Important: `host` and `port` are both optional, but at least one of them must be given.
    ///
    /// - Note: See `getaddrinfo(3)` for more details about the parameters.
    private init (host: String?, port: String?, hints: UnsafePointer<addrinfo>) throws {
        var info: UnsafeMutablePointer<addrinfo>? = nil
        let result: Int32 = getaddrinfo(host, port, hints, &info)

        guard result != -1 else { throw Socket.POSIXError.GetAddrInfoFailed(code: result) }
        guard let pointer = info else { throw Socket.POSIXError.NoAddressAvailable }
        _addrInfoStorage = Storage(addrInfoPointer: pointer)
    }
}


extension AddressInfoSequence: Sequence {
    func makeIterator () -> AddressInfoGenerator {
        return AddressInfoGenerator(storage: _addrInfoStorage)
    }
}

struct AddressInfoGenerator: IteratorProtocol {
    private let _storage: AddressInfoSequence.Storage
    private var _cursor: UnsafeMutablePointer<addrinfo>

	init (storage: AddressInfoSequence.Storage) {
        _storage = storage
        _cursor = storage._addrInfoPointer
    }

    mutating func next () -> addrinfo? {
		var info = _cursor.pointee
		
		guard let next = info.ai_next else { return nil }
        _cursor = next
        info.ai_next = nil // Prevent access to the next element of the linked list.
        return info
    }
}

extension AddressInfoSequence {
    /// Calls `f` with a copy of the first `addrinfo` in the sequence.
    func withFirstAddrInfo<R>(_ f: (addrinfo) throws -> R) rethrows -> R {
		return try f(_addrInfoStorage._addrInfoPointer.pointee)
    }
}


#if false // Doesn't work yet.
extension AddressInfoSequence: CustomStringConvertible {
    var description: String {
        return "[" + map { SocketAddress(addrInfo: $0).displayName }.reduce("") { $0 + ", " + $1 } + "]"
    }
}
#endif
