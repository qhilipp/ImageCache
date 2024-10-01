import SwiftCompilerPlugin
import SwiftUI
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import AppKit

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

enum ImageCacheError: CustomStringConvertible, Error {
	case internalError
	
	var description: String {
		switch self {
			case .internalError: "@ImageChage produced an internal error, please report"
		}
	}
}

/// Implementation of the `ImageCache` macro, which takes no arguments
/// and is attached to a variable of type `Data` and creates a computed property
/// that resembles that `Data` object as an `Image`. The `Data` object should
/// be named with a "Data"-suffix. For example
///
/// 	@ImageCache
/// 	var profilePictureData: Data?
///
/// 	will expand to
///
/// 	var profilePictureData: Data?
/// 	private var profilePictureHash: Int = 0
///		private var profilePictureCache: Image?
///		var profilePicture: Image? {
///			get {
///				if profilePictureData.hashValue != profilePictureHash,
///					let profilePictureData,
///					let uiImage = UIImage(data: profilePictureData)
///				{
///					profilePictureCache = Image(uiImage: uiImage)
///					profilePictureHash = profilePictureData.hashValue
///				}
///				return profilePictureCache
///			}
///		}
public struct ImageCacheMacro: PeerMacro {
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let suffix = "Data"
		guard let variableName = declaration.as(SwiftSyntax.VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
//			throw ImageCacheError.internalError
			return []
		}
		let prefixLength = variableName.index(variableName.endIndex, offsetBy: -suffix.count)
		let namePrefix = String(variableName[..<prefixLength])
		return ["""
		private var \(raw: namePrefix)Hash: Int = 0
		private var \(raw: namePrefix)Cache: Image?
		var \(raw: namePrefix): Image? {
			get {
				if \(raw: variableName).hashValue != \(raw: namePrefix)Hash,
					let \(raw: variableName),
					let uiImage = UIImage(data: \(raw: variableName))
				{
					\(raw: namePrefix)Cache = Image(uiImage: uiImage)
					\(raw: namePrefix)Hash = \(raw: variableName).hashValue
				}
				return \(raw: namePrefix)Cache
			}
		}
		"""]
	}
}

@main
struct ImageCachePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
		ImageCacheMacro.self
    ]
}
