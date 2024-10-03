import SwiftCompilerPlugin
import SwiftUI
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum ImageCacheError: CustomStringConvertible, Error {
	case internalError
	case onlyVariableDecl
	case mustHaveSuffix(String, String)
	case mustBeType(String, String)
	case emptyPrefix(String)
	case osNotSupported
	
	var description: String {
		switch self {
			case .internalError: "@ImageChage produced an internal error, please report"
			case .onlyVariableDecl: "@ImageCache only allows variable declarations"
			case .mustHaveSuffix(let variableIdentifier, let suffix): "@ImageCache requires \(variableIdentifier) to have the suffix \(suffix)"
			case .mustBeType(let variableIdentifier, let type): "@ImageCache requires \(variableIdentifier) to be of type \(type)"
			case .emptyPrefix(let variableIdentifier): "@ImageCache requires \(variableIdentifier) to have a prefix before \(variableIdentifier)"
			case .osNotSupported: "@ImageCache does not support this OS"
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
		let dataType = "Data"
		
		guard let variableDeclaration = declaration.as(SwiftSyntax.VariableDeclSyntax.self) else {
			throw ImageCacheError.onlyVariableDecl
		}
		
		guard let firstBinding = variableDeclaration.bindings.first else {
			throw ImageCacheError.onlyVariableDecl
		}
		
		guard let identifierPattern = firstBinding.pattern.as(IdentifierPatternSyntax.self) else {
			throw ImageCacheError.internalError
		}
		
		let variableIdentifier = identifierPattern.identifier.text
		
		guard firstBinding.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType.description == dataType else {
			throw ImageCacheError.mustBeType(variableIdentifier, dataType)
		}
		
		guard variableIdentifier.hasSuffix(dataType) else {
			throw ImageCacheError.mustHaveSuffix(variableIdentifier, dataType)
		}
		
		let prefixLength = variableIdentifier.index(variableIdentifier.endIndex, offsetBy: -dataType.count)
		let identifierPrefix = String(variableIdentifier[..<prefixLength])
		
		guard !identifierPrefix.isEmpty else {
			throw ImageCacheError.emptyPrefix(variableIdentifier)
		}
		
		let hashIdentifier = identifierPrefix.appending("Hash")
		let cacheIdentifier = identifierPrefix.appending("Cache")
		
		#if canImport(UIKit)
		let imageObtainment: DeclSyntax = "let uiImage = UIImage(data: \(raw: variableIdentifier))"
		let imageCacheInstallation: DeclSyntax = "\(raw: cacheIdentifier) = Image(uiImage: uiImage)"
		#elseif canImport(AppKit)
		let imageObtainment: DeclSyntax = "let nsImage = NSImage(data: \(raw: variableIdentifier))"
		let imageCacheInstallation: DeclSyntax = "\(raw: cacheIdentifier) = Image(nsImage: nsImage)"
		#else
		throw ImageCacheError.osNotSupported
		#endif
		
		return ["""
		private var \(raw: hashIdentifier): Int = 0
		private var \(raw: cacheIdentifier): Image?
		var \(raw: identifierPrefix): Image? {
			get {
				if \(raw: variableIdentifier).hashValue != \(raw: hashIdentifier),
					let \(raw: variableIdentifier),
					\(imageObtainment)
				{
					\(imageCacheInstallation)
					\(raw: hashIdentifier) = \(raw: variableIdentifier).hashValue
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
