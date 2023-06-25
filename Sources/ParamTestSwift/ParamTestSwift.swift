// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro than generate test methods using parameters.
///
/// ```swift
///     @ParameterizedTest([1, 2, 3])
///     func assertNumber(a: Int)
/// ```
///
/// generates three test methods such as named `testAssertNumber_0`.
@attached(peer, names: arbitrary)
public macro ParameterizedTest<T>(_ params: [T]) = #externalMacro(module: "ParamTestSwiftMacros", type: "ParameterizedTestMacro")
