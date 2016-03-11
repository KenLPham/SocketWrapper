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
    init?<T: WithUnsafeBufferPointerType where T.Element == UTF8.CodeUnit>(nulTerminatedUTF8: T) {
        guard let string = nulTerminatedUTF8.withUnsafeBufferPointer({ String(UTF8String: UnsafePointer($0.baseAddress))}) else {
            return nil
        }
        self = string
    }

    /// Initializes a `String` from a sequence of `UTF8.CodeUnit`s that conforms to `WithUnsafeBufferPointerType`. A `NUL`-terminator is not required.
    init?<T: WithUnsafeBufferPointerType where T.Element == UTF8.CodeUnit>(UTF8CodeUnits: T) {
        let string = UTF8CodeUnits.withUnsafeBufferPointer { NSString(bytes: $0.baseAddress, length: $0.count, encoding: NSUTF8StringEncoding) }
        if let string = string as? String {
            self = string
        } else {
            return nil
        }
    }

    /// Initializes a `String` from any sequence of `UTF8.CodeUnit`s. A `NUL`-terminator is not required.
    ///
    /// Note that this initializer may be slow because it must first convert the input sequence to an `Array`.
    init?<T: SequenceType where T.Generator.Element == UTF8.CodeUnit>(UTF8CodeUnitSequence: T) {
        self.init(UTF8CodeUnits: Array(UTF8CodeUnitSequence))
    }

    /// Initializes a `String` from a buffer of `UTF8.CodeUnit`. A `NUL`-terminator is not required.
    init?(UTF8CodeUnits buffer: UnsafeBufferPointer<UTF8.CodeUnit>) {
        if let string = NSString(bytes: buffer.baseAddress, length: buffer.count, encoding: NSUTF8StringEncoding) {
            self = string as String
        } else {
            return nil
        }
    }

    /// Initializes a `String` from a mutable buffer of `UTF8.CodeUnit`. A `NUL`-terminator is not required.
    ///
    /// This is a convenience initializer for when a `UnsafeMutableBufferPointer` exists already. It does not modify the input.
    init?(UTF8CodeUnits buffer: UnsafeMutableBufferPointer<UTF8.CodeUnit>) {
        self.init(UTF8CodeUnits: UnsafeBufferPointer(start: buffer.baseAddress, count: buffer.count))
    }

    /// Calls the given closure with a `UnsafeBufferPointer<UTF8.CodeUnit>` to an optionally `NUL`-terminated UTF-8 representation of the `String`.
    func withUTF8UnsafeBufferPointer<Result>(includeNulTerminator includeNulTerminator: Bool = true, @noescape f: UnsafeBufferPointer<UTF8.CodeUnit> throws -> Result) rethrows -> Result {
        return try nulTerminatedUTF8.withUnsafeBufferPointer { codeUnitBuffer in
            let cCharBufferCount = includeNulTerminator ? codeUnitBuffer.count : codeUnitBuffer.count - 1
            let cCharBuffer = UnsafeBufferPointer<UTF8.CodeUnit>(start: UnsafePointer(codeUnitBuffer.baseAddress), count: cCharBufferCount)
            return try f(cCharBuffer)
        }
    }
    
}


/// A common protocol of all array-like types that implement a `withUnsafeBufferPointer()` method.
protocol WithUnsafeBufferPointerType {
    associatedtype Element
    func withUnsafeBufferPointer<R>(@noescape body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R
}

extension Array: WithUnsafeBufferPointerType {

}

extension ArraySlice: WithUnsafeBufferPointerType {

}

extension ContiguousArray: WithUnsafeBufferPointerType {
    
}
