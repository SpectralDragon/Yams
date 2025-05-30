//
//  Representer.swift
//  Yams
//
//  Created by Norio Nomura on 1/8/17.
//  Copyright (c) 2017 Yams. All rights reserved.
//

import Foundation

public extension Node {
    /// Initialize a `Node` with a value of `NodeRepresentable`.
    ///
    /// - parameter representable: Value of `NodeRepresentable` to represent as a `Node`.
    ///
    /// - throws: `YamlError`.
    init<T: NodeRepresentable>(_ representable: T) throws {
        self = try representable.represented()
    }
}

// MARK: - NodeRepresentable
/// Type is representable as `Node`.
public protocol NodeRepresentable {
    /// This value's `Node` representation.
    func represented() throws -> Node
}

extension Node: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        return self
    }
}

extension Array: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let nodes = try map(represent)
        return Node(nodes, Tag(.seq))
    }
}

extension Dictionary: NodeRepresentable {
    /// This value's `Node` representation.
    public func represented() throws -> Node {
        let pairs = try map { (key: try represent($0.0), value: try represent($0.1)) }
        return Node(pairs.sorted { $0.key < $1.key }, Tag(.map))
    }
}

private func represent(_ value: Any) throws -> Node {
    if let representable = value as? NodeRepresentable {
        return try representable.represented()
    } else if (value as? NSDictionary)?.count == 0 {
        return .mapping(Node.Mapping([]))
    }
    throw YamlError.representer(problem: "Failed to represent \(value)")
}

// MARK: - ScalarRepresentable
/// Type is representable as `Node.scalar`.
public protocol ScalarRepresentable: NodeRepresentable {
    /// This value's `Node.scalar` representation.
    func represented(options: Emitter.Options) -> Node.Scalar
}

extension ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() throws -> Node {
        return .scalar(represented(options: .init()))
    }
}

extension NSNull: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init("null", Tag(.null))
    }
}

extension Bool: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(self ? "true" : "false", Tag(.bool))
    }
}

extension Data: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(base64EncodedString(), Tag(.binary))
    }
}

extension Date: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(iso8601String, Tag(.timestamp))
    }

    private var iso8601String: String {
        let (integral, millisecond) = timeIntervalSinceReferenceDate.separateFractionalSecond(withPrecision: 3)
        guard millisecond != 0 else { return iso8601Formatter.string(from: self) }

        let dateWithoutMillisecond = Date(timeIntervalSinceReferenceDate: integral)
        return iso8601WithoutZFormatter.string(from: dateWithoutMillisecond) +
            String(format: ".%03d", millisecond).trimmingCharacters(in: characterSetZero) + "Z"
    }

    private var iso8601StringWithFullNanosecond: String {
        let (integral, nanosecond) = timeIntervalSinceReferenceDate.separateFractionalSecond(withPrecision: 9)
        guard nanosecond != 0 else { return iso8601Formatter.string(from: self) }

        let dateWithoutNanosecond = Date(timeIntervalSinceReferenceDate: integral)
        return iso8601WithoutZFormatter.string(from: dateWithoutNanosecond) +
            String(format: ".%09d", nanosecond).trimmingCharacters(in: characterSetZero) + "Z"
    }
}

private extension TimeInterval {
    /// Separates the time interval into integral and fractional components, then rounds the `fractional`
    /// component to `precision` number of digits.
    ///
    /// - returns: Tuple of integral part and converted fractional part
    func separateFractionalSecond(withPrecision precision: Int) -> (integral: TimeInterval, fractional: Int) {
        var integral = 0.0
        let fractional = modf(self, &integral)

        let radix = pow(10.0, Double(precision))

        let rounded = Int((fractional * radix).rounded())
        let quotient = rounded / Int(radix)
        return quotient != 0 ? // carry-up?
            (integral + TimeInterval(quotient), rounded % Int(radix)) :
            (integral, rounded)
    }
}

private let characterSetZero = CharacterSet(charactersIn: "0")

private let iso8601Formatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

private let iso8601WithoutZFormatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

extension Double: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        let formattedString: String = formattedStringForCodable(
            value: self,
            floatingPointNumberFormatStrategy: options.floatingPointNumberFormatStrategy,
            formatter: doubleFormatter
        )
        return .init(formattedString.replacingOccurrences(of: "+-", with: "-"), Tag(.float))
    }
}

extension Float: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        let formattedString: String = formattedStringForCodable(
            value: self,
            floatingPointNumberFormatStrategy: options.floatingPointNumberFormatStrategy,
            formatter: floatFormatter
        )
        return .init(formattedString.replacingOccurrences(of: "+-", with: "-"), Tag(.float))
    }
}

private func numberFormatter(with significantDigits: Int) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .scientific
    formatter.usesSignificantDigits = true
    formatter.maximumSignificantDigits = significantDigits
    formatter.positiveInfinitySymbol = ".inf"
    formatter.negativeInfinitySymbol = "-.inf"
    formatter.notANumberSymbol = ".nan"
    formatter.exponentSymbol = "e+"
    return formatter
}

private let doubleFormatter = numberFormatter(with: 15)
private let floatFormatter = numberFormatter(with: 7)

// TODO: Support `Float80`
// extension Float80: ScalarRepresentable {}

extension BinaryInteger {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(String(describing: self), Tag(.int))
    }
}

extension Int: ScalarRepresentable {}
extension Int16: ScalarRepresentable {}
extension Int32: ScalarRepresentable {}
extension Int64: ScalarRepresentable {}
extension Int8: ScalarRepresentable {}
extension UInt: ScalarRepresentable {}
extension UInt16: ScalarRepresentable {}
extension UInt32: ScalarRepresentable {}
extension UInt64: ScalarRepresentable {}
extension UInt8: ScalarRepresentable {}

extension Optional: NodeRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented() throws -> Node {
        switch self {
        case let .some(wrapped):
            return try represent(wrapped)
        case .none:
            return Node("null", Tag(.null))
        }
    }
}

extension Decimal: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(description)
    }
}

extension URL: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(absoluteString)
    }
}

extension String: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        let scalar = Node.Scalar(self)
        return scalar.resolvedTag.name == .str ? scalar : .init(self, Tag(.str), .singleQuoted)
    }
}

extension UUID: ScalarRepresentable {
    /// This value's `Node.scalar` representation.
    public func represented(options: Emitter.Options) -> Node.Scalar {
        return .init(uuidString)
    }
}

// MARK: - ScalarRepresentableCustomizedForCodable

/// Types conforming to this protocol can be encoded by `YamlEncoder`.
public protocol YAMLEncodable: Encodable {
    /// Returns this value wrapped in a `Node`.
    func box(options: Emitter.Options) -> Node
}

extension YAMLEncodable where Self: ScalarRepresentable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box(options: Emitter.Options) -> Node {
        return .scalar(represented(options: options))
    }
}

extension Bool: YAMLEncodable {}
extension Data: YAMLEncodable {}
extension Decimal: YAMLEncodable {}
extension Int: YAMLEncodable {}
extension Int8: YAMLEncodable {}
extension Int16: YAMLEncodable {}
extension Int32: YAMLEncodable {}
extension Int64: YAMLEncodable {}
extension UInt: YAMLEncodable {}
extension UInt8: YAMLEncodable {}
extension UInt16: YAMLEncodable {}
extension UInt32: YAMLEncodable {}
extension UInt64: YAMLEncodable {}
extension URL: YAMLEncodable {}
extension String: YAMLEncodable {}
extension UUID: YAMLEncodable {}

extension Date: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box(options: Emitter.Options) -> Node {
        return Node(iso8601StringWithFullNanosecond, Tag(.timestamp))
    }
}

extension Double: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box(options: Emitter.Options) -> Node {
        let formattedString: String = formattedStringForCodable(
            value: self,
            floatingPointNumberFormatStrategy: options.floatingPointNumberFormatStrategy,
            formatter: doubleFormatter
        )
        return Node(formattedString, Tag(.float))
    }
}

extension Float: YAMLEncodable {
    /// Returns this value wrapped in a `Node.scalar`.
    public func box(options: Emitter.Options) -> Node {
        let formattedString: String = formattedStringForCodable(
            value: self,
            floatingPointNumberFormatStrategy: options.floatingPointNumberFormatStrategy,
            formatter: floatFormatter
        )
        return Node(formattedString, Tag(.float))
    }
}

private func formattedStringForCodable<T: FloatingPoint & CustomStringConvertible & CVarArg>(
    value: T,
    floatingPointNumberFormatStrategy: Emitter.FloatingPointNumberFormatStrategy,
    formatter: NumberFormatter
) -> String {
    if floatingPointNumberFormatStrategy == .decimal {
        switch value {
        case .infinity:
            return ".inf"
        case -.infinity:
            return "-.inf"
        case .nan:
            return ".nan"
        default:
            return value.description
        }
    }

    // Since `NumberFormatter` creates a string with insufficient precision for Decode,
    // it uses with `String(format:...)`
    let string = String(format: "%.*g", DBL_DECIMAL_DIG, value)
    // "%*.g" does not use scientific notation if the exponent is less than –4.
    // So fallback to using `NumberFormatter` if string does not uses scientific notation.
    guard string.lazy.suffix(5).contains("e") else {
        formatter.numberStyle = .scientific
        return formatter.string(for: value)!.replacingOccurrences(of: "+-", with: "-")
    }
    return string
}
