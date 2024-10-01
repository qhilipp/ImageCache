import SwiftCompilerPlugin
import SwiftUI
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import AppKit

enum ImageCacheError: CustomStringConvertible, Error {
	case internalError
	case onlyVariableDecl
	case onlyOneDecl
	case mustHaveSuffix(String, String)
	
	var description: String {
		switch self {
			case .internalError: "@ImageChage produced an internal error, please report"
			case .onlyVariableDecl: "@ImageCache only allows variable declarations"
			case .onlyOneDecl: "@ImageCache only allows one variable declaration"
			case .mustHaveSuffix(let variableIdentifier, let suffix): "@ImageCache requires \(variableIdentifier) to have the suffix \(suffix)"
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
		guard let variableDeclaration = declaration.as(SwiftSyntax.VariableDeclSyntax.self) else {
			throw ImageCacheError.onlyVariableDecl
		}
		
		guard variableDeclaration.bindings.count == 1 else {
			throw ImageCacheError.onlyOneDecl
		}
		
		guard let firstBinding = variableDeclaration.bindings.first else {
			throw ImageCacheError.internalError
		}
		
		guard let identifierPattern = firstBinding.pattern.as(IdentifierPatternSyntax.self) else {
			throw ImageCacheError.internalError
		}
		
		let variableIdentifier = identifierPattern.identifier.text
		let suffix = "Data"
		
		guard variableIdentifier.hasSuffix(suffix) else {
			throw ImageCacheError.mustHaveSuffix(variableIdentifier, suffix)
		}
		
		let prefixLength = variableIdentifier.index(variableIdentifier.endIndex, offsetBy: -suffix.count)
		let identifierPrefix = String(variableIdentifier[..<prefixLength])
		
		let hashIdentifier = identifierPrefix.appending("Hash")
		let cacheIdentifier = identifierPrefix.appending("Cache")
		
		return ["""
		private var \(raw: hashIdentifier): Int = 0
		private var \(raw: cacheIdentifier): Image?
		var \(raw: identifierPrefix): Image? {
			get {
				if \(raw: variableIdentifier).hashValue != \(raw: hashIdentifier),
					let \(raw: variableIdentifier),
					let uiImage = UIImage(data: \(raw: variableIdentifier))
				{
					\(raw: cacheIdentifier) = Image(uiImage: uiImage)
					\(raw: hashIdentifier) = \(raw: variableName).hashValue
				}
				return \(raw: cacheIdentifier)
			}
		}
		"""]
	}
}

@main
struct ImageCachePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
		ImageCacheMacro.self
    ]
}
