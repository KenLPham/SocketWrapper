//
//  main.swift
//  ChatServer
//
//  Created by Marco Masser on 2016-03-11.
//  Copyright © 2016 Objective Development Software GmbH. All rights reserved.
//

import Foundation

do {
    let port = "1234"
    let serverSocket = try ChatServer(port: port)
    try serverSocket.start()
    print("Chat server listening on port \(port)")
} catch {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}

dispatch_main() // Starts runloop, never returns
