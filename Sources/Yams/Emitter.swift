//
//  Emitter.swift
//  Yams
//
//  Created by Norio Nomura on 12/28/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

// swiftlint:disable duplicate_imports

#if SWIFT_PACKAGE
#if compiler(>=6)
internal import CYaml
#else
@_implementationOnly import CYaml
#endif
#endif
import Foundation

/// Produce a YAML string from objects.
///
/// - parameter objects:       Sequence of Objects.
/// - parameter canonical:     Output should be the "canonical" format as in the YAML specification.
/// - parameter indent:        The indentation increment.
/// - parameter width:         The preferred line width. @c -1 means unlimited.
/// - parameter allowUnicode:  Unescaped non-ASCII characters are allowed if true.
/// - parameter lineBreak:     Preferred line break.
/// - parameter explicitStart: Explicit document start `---`.
/// - parameter explicitEnd:   Explicit document end `...`.
/// - parameter version:       YAML version directive.
/// - parameter sortKeys:      Whether or not to sort Mapping keys in lexicographic order.
/// - parameter sequenceStyle: The style for sequences (arrays / lists)
/// - parameter mappingStyle:  The style for mappings (dictionaries)
///
/// - returns: YAML string.
///
/// - throws: `YamlError`.
public func dump<Objects>(
    objects: Objects,
    canonical: Bool = false,
    indent: Int = 0,
    width: Int = 0,
    allowUnicode: Bool = false,
    lineBreak: Emitter.LineBreak = .ln,
    explicitStart: Bool = false,
    explicitEnd: Bool = false,
    version: (major: Int, minor: Int)? = nil,
    sortKeys: Bool = false,
    sequenceStyle: Node.Sequence.Style = .any,
    mappingStyle: Node.Mapping.Style = .any,
    newLineScalarStyle: Node.Scalar.Style = .any) throws -> String
    where Objects: Sequence {
    func representable(from object: Any) throws -> NodeRepresentable {
        if let representable = object as? NodeRepresentable {
            return representable
        }
        throw YamlError.emitter(problem: "\(object) does not conform to NodeRepresentable!")
    }
    let nodes = try objects.map(representable(from:)).map { try $0.represented() }
    return try serialize(
        nodes: nodes,
        canonical: canonical,
        indent: indent,
        width: width,
        allowUnicode: allowUnicode,
        lineBreak: lineBreak,
        explicitStart: explicitStart,
        explicitEnd: explicitEnd,
        version: version,
        sortKeys: sortKeys,
        sequenceStyle: sequenceStyle,
        mappingStyle: mappingStyle,
        newLineScalarStyle: newLineScalarStyle
    )
}

/// Produce a YAML string from an object.
///
/// - parameter object:        Object.
/// - parameter canonical:     Output should be the "canonical" format as in the YAML specification.
/// - parameter indent:        The indentation increment.
/// - parameter width:         The preferred line width. @c -1 means unlimited.
/// - parameter allowUnicode:  Unescaped non-ASCII characters are allowed if true.
/// - parameter lineBreak:     Preferred line break.
/// - parameter explicitStart: Explicit document start `---`.
/// - parameter explicitEnd:   Explicit document end `...`.
/// - parameter version:       YAML version directive.
/// - parameter sortKeys:      Whether or not to sort Mapping keys in lexicographic order.
/// - parameter sequenceStyle: The style for sequences (arrays / lists)
/// - parameter mappingStyle:  The style for mappings (dictionaries)
///
/// - returns: YAML string.
///
/// - throws: `YamlError`.
public func dump(
    object: Any?,
    canonical: Bool = false,
    indent: Int = 0,
    width: Int = 0,
    allowUnicode: Bool = false,
    lineBreak: Emitter.LineBreak = .ln,
    explicitStart: Bool = false,
    explicitEnd: Bool = false,
    version: (major: Int, minor: Int)? = nil,
    sortKeys: Bool = false,
    sequenceStyle: Node.Sequence.Style = .any,
    mappingStyle: Node.Mapping.Style = .any,
    newLineScalarStyle: Node.Scalar.Style = .any,
    redundancyAliasingStrategy: RedundancyAliasingStrategy? = nil) throws -> String {
    return try serialize(
        node: object.represented(),
        canonical: canonical,
        indent: indent,
        width: width,
        allowUnicode: allowUnicode,
        lineBreak: lineBreak,
        explicitStart: explicitStart,
        explicitEnd: explicitEnd,
        version: version,
        sortKeys: sortKeys,
        sequenceStyle: sequenceStyle,
        mappingStyle: mappingStyle,
        newLineScalarStyle: newLineScalarStyle,
        redundancyAliasingStrategy: redundancyAliasingStrategy
    )
}

/// Produce a YAML string from a `Node`.
///
/// - parameter nodes:         Sequence of `Node`s.
/// - parameter canonical:     Output should be the "canonical" format as in the YAML specification.
/// - parameter indent:        The indentation increment.
/// - parameter width:         The preferred line width. @c -1 means unlimited.
/// - parameter allowUnicode:  Unescaped non-ASCII characters are allowed if true.
/// - parameter lineBreak:     Preferred line break.
/// - parameter explicitStart: Explicit document start `---`.
/// - parameter explicitEnd:   Explicit document end `...`.
/// - parameter version:       YAML version directive.
/// - parameter sortKeys:      Whether or not to sort Mapping keys in lexicographic order.
/// - parameter sequenceStyle: The style for sequences (arrays / lists)
/// - parameter mappingStyle:  The style for mappings (dictionaries)
///
/// - returns: YAML string.
///
/// - throws: `YamlError`.
public func serialize<Nodes>(
    nodes: Nodes,
    canonical: Bool = false,
    indent: Int = 0,
    width: Int = 0,
    allowUnicode: Bool = false,
    lineBreak: Emitter.LineBreak = .ln,
    explicitStart: Bool = false,
    explicitEnd: Bool = false,
    version: (major: Int, minor: Int)? = nil,
    sortKeys: Bool = false,
    sequenceStyle: Node.Sequence.Style = .any,
    mappingStyle: Node.Mapping.Style = .any,
    newLineScalarStyle: Node.Scalar.Style = .any,
    redundancyAliasingStrategy: RedundancyAliasingStrategy? = nil) throws -> String
    where Nodes: Sequence, Nodes.Iterator.Element == Node {
    let emitter = Emitter(
        canonical: canonical,
        indent: indent,
        width: width,
        allowUnicode: allowUnicode,
        lineBreak: lineBreak,
        explicitStart: explicitStart,
        explicitEnd: explicitEnd,
        version: version,
        sortKeys: sortKeys,
        sequenceStyle: sequenceStyle,
        mappingStyle: mappingStyle,
        newLineScalarStyle: newLineScalarStyle,
        redundancyAliasingStrategy: redundancyAliasingStrategy
    )
    try emitter.open()
    try nodes.forEach(emitter.serialize)
    try emitter.close()
    return String(data: emitter.data, encoding: .utf8)!
}

/// Produce a YAML string from a `Node`.
///
/// - parameter node:          `Node`.
/// - parameter canonical:     Output should be the "canonical" format as in the YAML specification.
/// - parameter indent:        The indentation increment.
/// - parameter width:         The preferred line width. @c -1 means unlimited.
/// - parameter allowUnicode:  Unescaped non-ASCII characters are allowed if true.
/// - parameter lineBreak:     Preferred line break.
/// - parameter explicitStart: Explicit document start `---`.
/// - parameter explicitEnd:   Explicit document end `...`.
/// - parameter version:       YAML version directive.
/// - parameter sortKeys:      Whether or not to sort Mapping keys in lexicographic order.
/// - parameter sequenceStyle: The style for sequences (arrays / lists)
/// - parameter mappingStyle:  The style for mappings (dictionaries)
///
/// - returns: YAML string.
///
/// - throws: `YamlError`.
public func serialize(
    node: Node,
    canonical: Bool = false,
    indent: Int = 0,
    width: Int = 0,
    allowUnicode: Bool = false,
    lineBreak: Emitter.LineBreak = .ln,
    explicitStart: Bool = false,
    explicitEnd: Bool = false,
    version: (major: Int, minor: Int)? = nil,
    sortKeys: Bool = false,
    sequenceStyle: Node.Sequence.Style = .any,
    mappingStyle: Node.Mapping.Style = .any,
    newLineScalarStyle: Node.Scalar.Style = .any,
    redundancyAliasingStrategy: RedundancyAliasingStrategy? = nil) throws -> String {
    return try serialize(
        nodes: [node],
        canonical: canonical,
        indent: indent,
        width: width,
        allowUnicode: allowUnicode,
        lineBreak: lineBreak,
        explicitStart: explicitStart,
        explicitEnd: explicitEnd,
        version: version,
        sortKeys: sortKeys,
        sequenceStyle: sequenceStyle,
        mappingStyle: mappingStyle,
        newLineScalarStyle: newLineScalarStyle,
        redundancyAliasingStrategy: redundancyAliasingStrategy
    )
}

/// Class responsible for emitting libYAML events.
public final class Emitter {
    /// Line break options to use when emitting YAML.
    public enum LineBreak {
        /// Use CR for line breaks (Mac style).
        case cr
        /// Use LN for line breaks (Unix style).
        case ln
        /// Use CR LN for line breaks (DOS style).
        case crln
    }

    /// Floating point number format style to use when emitting YAML.
    public enum FloatingPointNumberFormatStrategy {
        /// Use scientific notation.
        case scientific
        /// Use decimal notation.
        case decimal
    }

    /// Retrieve this Emitter's binary output.
    public internal(set) var data = Data()

    /// Configuration options to use when emitting YAML.
    public struct Options {
        /// Set if the output should be in the "canonical" format described in the YAML specification.
        public var canonical: Bool = false
        /// Set the indentation value.
        public var indent: Int = 0
        /// Set the preferred line width. -1 means unlimited.
        public var width: Int = 0
        /// Set if unescaped non-ASCII characters are allowed.
        public var allowUnicode: Bool = false
        /// Set the preferred line break.
        public var lineBreak: LineBreak = .ln
        /// Set to emit an explicit document start marker.
        public var explicitStart: Bool = false
        /// Set to emit an explicit document end marker.
        public var explicitEnd: Bool = false

        /// The `%YAML` directive value or nil.
        public var version: (major: Int, minor: Int)?

        /// Set if emitter should sort keys in lexicographic order.
        public var sortKeys: Bool = false

        /// Set the style for sequences (arrays / lists)
        public var sequenceStyle: Node.Sequence.Style = .any

        /// Set the style for mappings (dictionaries)
        public var mappingStyle: Node.Mapping.Style = .any

        /// Set the style for scalars that include newlines
        public var newLineScalarStyle: Node.Scalar.Style = .any

        /// Redundancy aliasing strategy to use when encoding. Defaults to nil
        public var redundancyAliasingStrategy: RedundancyAliasingStrategy?

        /// Set the number format strategy to use when emitting YAML.
        public var floatingPointNumberFormatStrategy: FloatingPointNumberFormatStrategy = .scientific

        /// Create `Emitter.Options` with the specified values.
        ///
        /// - parameter canonical:     Set if the output should be in the "canonical" format described in the YAML
        ///                            specification.
        /// - parameter indent:        Set the indentation value.
        /// - parameter width:         Set the preferred line width. -1 means unlimited.
        /// - parameter allowUnicode:  Set if unescaped non-ASCII characters are allowed.
        /// - parameter lineBreak:     Set the preferred line break.
        /// - parameter explicitStart: Explicit document start `---`.
        /// - parameter explicitEnd:   Explicit document end `...`.
        /// - parameter version:       The `%YAML` directive value or nil.
        /// - parameter sortKeys:      Set if emitter should sort keys in lexicographic order.
        /// - parameter sequenceStyle: Set the style for sequences (arrays / lists)
        /// - parameter mappingStyle:  Set the style for mappings (dictionaries)
        /// - parameter newLineScalarStyle: Set the style for newline-containing scalars
        /// - parameter redundancyAliasingStrategy: Set the strategy for identifying
        /// - parameter numberFormatStrategy: Set the number format strategy to use when emitting YAML.
        /// redundant structures and automatically aliasing them
        public init(canonical: Bool = false, indent: Int = 0, width: Int = 0, allowUnicode: Bool = false,
                    lineBreak: Emitter.LineBreak = .ln,
                    explicitStart: Bool = false,
                    explicitEnd: Bool = false,
                    version: (major: Int, minor: Int)? = nil,
                    sortKeys: Bool = false, sequenceStyle: Node.Sequence.Style = .any,
                    mappingStyle: Node.Mapping.Style = .any,
                    newLineScalarStyle: Node.Scalar.Style = .any,
                    redundancyAliasingStrategy: RedundancyAliasingStrategy? = nil,
                    floatingPointNumberFormatStrategy: FloatingPointNumberFormatStrategy = .scientific) {
            self.canonical = canonical
            self.indent = indent
            self.width = width
            self.allowUnicode = allowUnicode
            self.lineBreak = lineBreak
            self.explicitStart = explicitStart
            self.explicitEnd = explicitEnd
            self.version = version
            self.sortKeys = sortKeys
            self.sequenceStyle = sequenceStyle
            self.mappingStyle = mappingStyle
            self.newLineScalarStyle = newLineScalarStyle
            self.redundancyAliasingStrategy = redundancyAliasingStrategy
            self.floatingPointNumberFormatStrategy = floatingPointNumberFormatStrategy
        }
    }

    /// Configuration options to use when emitting YAML.
    public var options: Options {
        didSet {
            applyOptionsToEmitter()
        }
    }

    /// Create an `Emitter` with the specified options.
    ///
    /// - parameter canonical:     Set if the output should be in the "canonical" format described in the YAML
    ///                            specification.
    /// - parameter indent:        Set the indentation value.
    /// - parameter width:         Set the preferred line width. -1 means unlimited.
    /// - parameter allowUnicode:  Set if unescaped non-ASCII characters are allowed.
    /// - parameter lineBreak:     Set the preferred line break.
    /// - parameter explicitStart: Explicit document start `---`.
    /// - parameter explicitEnd:   Explicit document end `...`.
    /// - parameter version:       The `%YAML` directive value or nil.
    /// - parameter sortKeys:      Set if emitter should sort keys in lexicographic order.
    /// - parameter sequenceStyle: Set the style for sequences (arrays / lists)
    /// - parameter mappingStyle:  Set the style for mappings (dictionaries)
    /// - parameter newLineScalarStyle: Set the style for newline-containing scalars
    /// - parameter redundancyAliasingStrategy: Set the strategy for identifying redundant
    /// - parameter numberFormatStrategy: Set the number format strategy to use when emitting YAML.
    /// structures and automatically aliasing them
    public init(canonical: Bool = false,
                indent: Int = 0,
                width: Int = 0,
                allowUnicode: Bool = false,
                lineBreak: LineBreak = .ln,
                explicitStart: Bool = false,
                explicitEnd: Bool = false,
                version: (major: Int, minor: Int)? = nil,
                sortKeys: Bool = false,
                sequenceStyle: Node.Sequence.Style = .any,
                mappingStyle: Node.Mapping.Style = .any,
                newLineScalarStyle: Node.Scalar.Style = .any,
                redundancyAliasingStrategy: RedundancyAliasingStrategy? = nil,
                floatingPointNumberFormatStrategy: FloatingPointNumberFormatStrategy = .scientific) {
        options = Options(canonical: canonical,
                          indent: indent,
                          width: width,
                          allowUnicode: allowUnicode,
                          lineBreak: lineBreak,
                          explicitStart: explicitStart,
                          explicitEnd: explicitEnd,
                          version: version,
                          sortKeys: sortKeys,
                          sequenceStyle: sequenceStyle,
                          mappingStyle: mappingStyle,
                          newLineScalarStyle: newLineScalarStyle,
                          redundancyAliasingStrategy: redundancyAliasingStrategy,
                          floatingPointNumberFormatStrategy: floatingPointNumberFormatStrategy)
        // configure emitter
        yaml_emitter_initialize(&emitter)
        yaml_emitter_set_output(&self.emitter, { pointer, buffer, size in
            guard let buffer = buffer else { return 0 }
            let emitter = unsafeBitCast(pointer, to: Emitter.self)
            emitter.data.append(buffer, count: size)
            return 1
        }, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))

        applyOptionsToEmitter()

        yaml_emitter_set_encoding(&emitter, YAML_UTF8_ENCODING)
    }

    deinit {
        yaml_emitter_delete(&emitter)
    }

    /// Open & initialize the emitter.
    ///
    /// - throws: `YamlError` if the `Emitter` was already opened or closed.
    public func open() throws {
        switch state {
        case .initialized:
            var event = yaml_event_t()
            yaml_stream_start_event_initialize(&event, YAML_UTF8_ENCODING)
            try emit(&event)
            state = .opened
        case .opened:
            throw YamlError.emitter(problem: "serializer is already opened")
        case .closed:
            throw YamlError.emitter(problem: "serializer is closed")
        }
    }

    /// Close the `Emitter.`
    ///
    /// - throws: `YamlError` if the `Emitter` hasn't yet been initialized.
    public func close() throws {
        switch state {
        case .initialized:
            throw YamlError.emitter(problem: "serializer is not opened")
        case .opened:
            var event = yaml_event_t()
            yaml_stream_end_event_initialize(&event)
            try emit(&event)
            state = .closed
        case .closed:
            break // do nothing
        }
    }

    /// Ingest a `Node` to include when emitting the YAML output.
    ///
    /// - parameter node: The `Node` to serialize.
    ///
    /// - throws: `YamlError` if the `Emitter` hasn't yet been opened or has been closed.
    public func serialize(node: Node) throws {
        switch state {
        case .initialized:
            throw YamlError.emitter(problem: "serializer is not opened")
        case .opened:
            break
        case .closed:
            throw YamlError.emitter(problem: "serializer is closed")
        }
        var event = yaml_event_t()
        if let (major, minor) = options.version {
            var versionDirective = yaml_version_directive_t(major: Int32(major), minor: Int32(minor))
            // TODO: Support tags
            yaml_document_start_event_initialize(&event, &versionDirective, nil, nil, options.explicitStart ? 0 : 1)
        } else {
            // TODO: Support tags
            yaml_document_start_event_initialize(&event, nil, nil, nil, options.explicitStart ? 0 : 1)
        }

        try emit(&event)
        try serializeNode(node)
        yaml_document_end_event_initialize(&event, options.explicitEnd ? 0 : 1)
        try emit(&event)
    }

    // MARK: Private
    private var emitter = yaml_emitter_t()

    private enum State { case initialized, opened, closed }
    private var state: State = .initialized

    private func applyOptionsToEmitter() {
        yaml_emitter_set_canonical(&emitter, options.canonical ? 1 : 0)
        yaml_emitter_set_indent(&emitter, Int32(options.indent))
        yaml_emitter_set_width(&emitter, Int32(options.width))
        yaml_emitter_set_unicode(&emitter, options.allowUnicode ? 1 : 0)
        switch options.lineBreak {
        case .cr: yaml_emitter_set_break(&emitter, YAML_CR_BREAK)
        case .ln: yaml_emitter_set_break(&emitter, YAML_LN_BREAK)
        case .crln: yaml_emitter_set_break(&emitter, YAML_CRLN_BREAK)
        }
    }
}

// MARK: Implementation Details

extension Emitter {
    private func emit(_ event: UnsafeMutablePointer<yaml_event_t>) throws {
        guard yaml_emitter_emit(&emitter, event) == 1 else {
            throw YamlError(from: emitter)
        }
    }

    private func serializeNode(_ node: Node) throws {
        switch node {
        case .scalar(let scalar): try serializeScalar(scalar)
        case .sequence(let sequence): try serializeSequence(sequence)
        case .mapping(let mapping): try serializeMapping(mapping)
        case .alias(let alias): try serializeAlias(alias)
        }
    }

    private func serializeAlias(_ alias: Node.Alias) throws {
        var event = yaml_event_t()
        let anchor = alias.anchor.rawValue
        yaml_alias_event_initialize(&event,
                                    anchor)
        try emit(&event)
    }

    private func serializeScalar(_ scalar: Node.Scalar) throws {
        var value = scalar.string.utf8CString, tag = scalar.resolvedTag.name.rawValue.utf8CString
        let scalarStyle = yaml_scalar_style_t(rawValue: numericCast(scalar.style.rawValue))
        var event = yaml_event_t()
        _ = value.withUnsafeMutableBytes { value in
            tag.withUnsafeMutableBytes { tag in
                yaml_scalar_event_initialize(
                    &event,
                    scalar.anchor?.rawValue,
                    tag.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    value.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    Int32(value.count - 1),
                    1,
                    1,
                    scalarStyle)
            }
        }
        try emit(&event)
    }

    private func serializeSequence(_ sequence: Node.Sequence) throws {
        var tag = sequence.resolvedTag.name.rawValue.utf8CString
        let implicit: Int32 = sequence.tag.name == .seq ? 1 : 0
        let sequenceStyle = yaml_sequence_style_t(rawValue: numericCast(sequence.style.rawValue))
        var event = yaml_event_t()
        _ = tag.withUnsafeMutableBytes { tag in
            yaml_sequence_start_event_initialize(
                &event,
                sequence.anchor?.rawValue,
                tag.baseAddress?.assumingMemoryBound(to: UInt8.self),
                implicit,
                sequenceStyle)
        }
        try emit(&event)
        try sequence.forEach(self.serializeNode)
        yaml_sequence_end_event_initialize(&event)
        try emit(&event)
    }

    private func serializeMapping(_ mapping: Node.Mapping) throws {
        var tag = mapping.resolvedTag.name.rawValue.utf8CString
        let implicit: Int32 = mapping.tag.name == .map ? 1 : 0
        let mappingStyle = yaml_mapping_style_t(rawValue: numericCast(mapping.style.rawValue))
        var event = yaml_event_t()
        _ = tag.withUnsafeMutableBytes { tag in
            yaml_mapping_start_event_initialize(
                &event,
                mapping.anchor?.rawValue,
                tag.baseAddress?.assumingMemoryBound(to: UInt8.self),
                implicit,
                mappingStyle)
        }
        try emit(&event)
        if options.sortKeys {
            try mapping.keys.sorted().forEach {
                try self.serializeNode($0)
                try self.serializeNode(mapping[$0]!) // swiftlint:disable:this force_unwrapping
            }
        } else {
            try mapping.forEach {
                try self.serializeNode($0.key)
                try self.serializeNode($0.value)
            }
        }
        yaml_mapping_end_event_initialize(&event)
        try emit(&event)
    }
}

// swiftlint:disable:this file_length
