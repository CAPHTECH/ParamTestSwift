import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import ParamTestSwiftMacros

let testMacros: [String: Macro.Type] = [
    "ParameterizedTest": ParameterizedTestMacro.self,
]

final class ParamTestSwiftTests: XCTestCase {
    func testMacroWithIntArray() {
        assertMacroExpansion(
            """
            @ParameterizedTest([1])
            func assertNumber(a: Int) {}
            """,
            expandedSource: """
            
            func assertNumber(a: Int) {
            }
            func testAssertNumber_0()  {
                let a: Int = 1
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithTupleArray() {
        assertMacroExpansion(
            """
            @ParameterizedTest([(1, 2)])
            func assertNumbers(a: Int, b: Int) {
                assert(a == b)
            }
            """,
            expandedSource: """
            
            func assertNumbers(a: Int, b: Int) {
                assert(a == b)
            }
            func testAssertNumbers_0()  {
                let a: Int = 1
                let b: Int = 2
                assert(a == b)
            }
            """,
            macros: testMacros
        )
    }
}
