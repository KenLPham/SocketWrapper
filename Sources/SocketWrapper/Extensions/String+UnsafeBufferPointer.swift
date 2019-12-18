//
//  String+UnsafeBufferPointer.swift
//  SocketWrapper
//
//  Created by Christian Ludl on 2016-02-11.
//  Copyright © 2016 Objective Development. All rights reserved.
//

import Foundation

extension String {
    /// Initializes a `String` from a sequence of `NUL`-terminated `UTF8.CodeUnit` as a `WithUnsafeBufferPointerType`.
	init?<T: WithUnsafeBufferPointerType> (nulTerminatedUTF8: T) where T.Element == UTF8.CodeUnit {
		guard let string = nulTerminatedUTF8.withUnsafeBufferPointer({ String(bytes: $0, encoding: .utf8) }) else {
            return nil
        }
        self = string
    }

    /// Initializes a `String` from a sequence of `UTF8.CodeUnit`s that conforms to `WithUnsafeBufferPointerType`. A `NUL`-terminator is not required.
	init?<T: WithUnsafeBufferPointerType> (UTF8CodeUnits: T) where T.Element == UTF8.CodeUnit {
		let str = UTF8CodeUnits.withUnsafeBufferPointer { String(bytes: $0, encoding: .utf8) }
		guard let s = str else { return nil }
		self = s
    }

    /// Initializes a `String` from any sequence of `UTF8.CodeUnit`s. A `NUL`-terminator is not required.
    ///
    /// Note that this initializer may be slow because it must first convert the input sequence to an `Array`.
	init?<T: Sequence> (UTF8CodeUnitSequence: T) where T.Iterator.Element == UTF8.CodeUnit {
		self.init(UTF8CodeUnits: Array(UTF8CodeUnitSequence))
    }

    /// Initializes a `String` from a buffer of `UTF8.CodeUnit`. A `NUL`-terminator is not required.
    init? (UTF8CodeUnits buffer: UnsafeBufferPointer<UTF8.CodeUnit>) {
		guard let str = String(bytes: buffer, encoding: .utf8) else { return nil }
		self = str
    }

    /// Initializes a `String` from a mutable buffer of `UTF8.CodeUnit`. A `NUL`-terminator is not required.
    ///
    /// This is a convenience initializer for when a `UnsafeMutableBufferPointer` exists already. It does not modify the input.
    init? (UTF8CodeUnits buffer: UnsafeMutableBufferPointer<UTF8.CodeUnit>) {
        self.init(UTF8CodeUnits: UnsafeBufferPointer(start: buffer.baseAddress, count: buffer.count))
    }

    /// Calls the given closure with a `UnsafeBufferPointer<UTF8.CodeUnit>` to an optionally `NUL`-terminated UTF-8 representation of the `String`.
	func withUTF8UnsafeBufferPointer<Result> (includeNulTerminator: Bool = true, f: (UnsafeBufferPointer<UTF8.CodeUnit>) throws -> Result) rethrows -> Result {
//		return try utf8CString.withUnsafeBufferPointer { codeUnitBuffer in
//			let cCharBufferCount = includeNulTerminator ? codeUnitBuffer.count : codeUnitBuffer.count - 1
//			let cCharBuffer = UnsafeBufferPointer<UTF8.CodeUnit>(start: UnsafePointer(codeUnitBuffer.baseAddress), count: cCharBufferCount)
//			return try f(cCharBuffer)
//		}
		
		return try utf8CString.withUnsafeBufferPointer { unitBuffer in
//			let count = includeNulTerminator ? unitBuffer.count : unitBuffer.count - 1
			return try unitBuffer.withMemoryRebound(to: UTF8.CodeUnit.self) { try f($0) }
		}
    }
}


/// A common protocol of all array-like types that implement a `withUnsafeBufferPointer()` method.
protocol WithUnsafeBufferPointerType {
    associatedtype Element
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R
}

extension Array: WithUnsafeBufferPointerType {}

extension ArraySlice: WithUnsafeBufferPointerType {}

extension ContiguousArray: WithUnsafeBufferPointerType {}
