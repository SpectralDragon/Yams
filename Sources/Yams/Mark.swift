//
//  Mark.swift
//  Yams
//
//  Created by Norio Nomura on 4/11/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

/// The pointer position.
public struct Mark: Sendable {
    /// Line number starting from 1.
    public let line: Int
    /// Column number starting from 1. libYAML counts columns in `UnicodeScalar`.
    public let column: Int
}

// MARK: - CustomStringConvertible Conformance

extension Mark: CustomStringConvertible {
    /// A textual representation of this instance.
    public var description: String { return "\(line):\(column)" }
}

// MARK: Snippet

extension Mark {
    /// Returns snippet string pointed by Mark instance from YAML String.
    public func snippet(from yaml: String) -> String {
        let contents = yaml.substring(at: line - 1)
        let columnIndex = contents.unicodeScalars
            .index(contents.unicodeScalars.startIndex,
                   offsetBy: column - 1,
                   limitedBy: contents.unicodeScalars.endIndex)?
            .samePosition(in: contents.utf16) ?? contents.utf16.endIndex
        let columnInUTF16 = contents.utf16.distance(from: contents.utf16.startIndex, to: columnIndex)
        return contents.endingWithNewLine +
            String(repeating: " ", count: columnInUTF16) + "^"
    }
}
