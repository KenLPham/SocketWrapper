# SwiftPOSIX 

POSIX socket API wrapper written in Swift.

# TODO

Here’s a very incomplete list of things that could be added or changed:
- Implement support for other protocols than TCP. The low-level `Socket` struct probably doesn’t need any changes for that, but the higher-level `SocketType` sub-protocols don’t expose initializers for that.
- getaddrinfo() returns a linked list of results and only the very first one is used for `connect()`/`accept()`. That list should probably be traversed until those calls actually succeed. 

# Credit

Updated from [SocketWrapper](https://github.com/obdev/SocketWrapper)
