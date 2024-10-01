import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ImageCacheMacros)
import ImageCacheMacros

let testMacros: [String: Macro.Type] = [
    "ImageCache": ImageCacheMacro.self,
]
#endif

final class ImageCacheTests: XCTestCase {
    func testMacro() throws {
        #if canImport(ImageCacheMacros)
        assertMacroExpansion(
			"""
			@ImageCache
			var testData: Data?
			""",
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
