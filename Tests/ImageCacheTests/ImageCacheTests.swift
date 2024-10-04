import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import ImageCacheMacros

let testMacros: [String: Macro.Type] = [
    "ImageCache": ImageCacheMacro.self,
]

final class ImageCacheTests: XCTestCase {
    func testSuccessfulMacroExpansion() {
        assertMacroExpansion(
			"""
			@ImageCache(false)
			var testData: Data?
			""",
            expandedSource:
			"""
			var testData: Data?

			private var testHash: Int = 0
			private var testCache: Image?
			var test: Image? {
				get {
					if testData.hashValue != testHash,
						let testData,
						let nsImage = NSImage(data: testData)
					{
						testCache = Image(nsImage: nsImage)
						testHash = testData.hashValue
					}
					return testCache
				}
			}
			""",
            macros: testMacros
        )
		assertMacroExpansion(
			"""
			@ImageCache
			var testData: Data?
			""",
			expandedSource:
			"""
			var testData: Data?

			@Transient private var testHash: Int = 0
			@Transient private var testCache: Image?
			var test: Image? {
				get {
					if testData.hashValue != testHash,
						let testData,
						let nsImage = NSImage(data: testData)
					{
						testCache = Image(nsImage: nsImage)
						testHash = testData.hashValue
					}
					return testCache
				}
			}
			""",
			macros: testMacros
		)
    }
	
	func testMissingSuffix() {
		assertMacroExpansion(
			"""
			@ImageCache
			var test: Data?
			""",
			expandedSource: "var test: Data?",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.mustHaveSuffix("test", "Data").description, line: 1, column: 1)],
			macros: testMacros
		)
		assertMacroExpansion(
			"""
			@ImageCache
			var testDataObject: Data?
			""",
			expandedSource: "var testDataObject: Data?",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.mustHaveSuffix("testDataObject", "Data").description, line: 1, column: 1)],
			macros: testMacros
		)
		assertMacroExpansion(
			"""
			@ImageCache
			var testdata: Data?
			""",
			expandedSource: "var testdata: Data?",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.mustHaveSuffix("testdata", "Data").description, line: 1, column: 1)],
			macros: testMacros
		)
	}
	
	func testEmptyPrefix() {
		assertMacroExpansion(
			"""
			@ImageCache
			var Data: Data?
			""",
			expandedSource: "var Data: Data?",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.emptyPrefix("Data").description, line: 1, column: 1)],
			macros: testMacros
		)
	}
	
	func testWrongType() {
		assertMacroExpansion(
			"""
			@ImageCache
			var testData: Data
			""",
			expandedSource: "var testData: Data",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.mustBeType("testData", "Data?").description, line: 1, column: 1)],
			macros: testMacros
		)
		assertMacroExpansion(
			"""
			@ImageCache
			var testData: String
			""",
			expandedSource: "var testData: String",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.mustBeType("testData", "Data?").description, line: 1, column: 1)],
			macros: testMacros
		)
		assertMacroExpansion(
			"""
			@ImageCache
			var testData: String?
			""",
			expandedSource: "var testData: String?",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.mustBeType("testData", "Data?").description, line: 1, column: 1)],
			macros: testMacros
		)
	}
	
	func testWrongDeclType() {
		assertMacroExpansion(
			"""
			@ImageCache
			class TestData {}
			""",
			expandedSource: "class TestData {}",
			diagnostics: [DiagnosticSpec(message: ImageCacheError.onlyVariableDecl.description, line: 1, column: 1)],
			macros: testMacros
		)
	}
}
