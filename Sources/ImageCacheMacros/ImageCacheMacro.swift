import SwiftCompilerPlugin
import SwiftUI
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ImageCacheError: CustomStringConvertible, Error {
	case internalError
	case onlyVariableDecl
	case mustHaveSuffix(String, String)
	case mustBeType(String, String)
	case emptyPrefix(String)
	case osNotSupported
	case mustBeBoolLiteral
	
	public var description: String {
		switch self {
			case .internalError: "@ImageChage produced an internal error, please report"
			case .onlyVariableDecl: "@ImageCache only allows variable declarations"
			case .mustHaveSuffix(let variableIdentifier, let suffix): "@ImageCache requires \(variableIdentifier) to have the suffix \(suffix)"
			case .mustBeType(let variableIdentifier, let type): "@ImageCache requires \(variableIdentifier) to be of type \(type)"
			case .emptyPrefix(let variableIdentifier): "@ImageCache requires \(variableIdentifier) to have a prefix before \(variableIdentifier)"
			case .osNotSupported: "@ImageCache does not support this OS"
			case .mustBeBoolLiteral: "@ImageCache only accepts a bool literal argument"
		}
	}
}

public struct ImageCacheMacro: PeerMacro {
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let dataType = "Data?"
		let unwrappedDataType = String(dataType.dropLast())
		
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
		
		guard firstBinding.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.description == dataType else {
			throw ImageCacheError.mustBeType(variableIdentifier, dataType)
		}
		
		guard variableIdentifier.hasSuffix(unwrappedDataType) else {
			throw ImageCacheError.mustHaveSuffix(variableIdentifier, unwrappedDataType)
		}
		
		let identifierPrefix = String(variableIdentifier.dropLast(unwrappedDataType.count))
		
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
		
		let argumentsList = node.arguments?.as(LabeledExprListSyntax.self) ?? []
		
		let useSwiftData: Bool
		if !argumentsList.isEmpty {
			guard let tokenKind = argumentsList.first?.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind else {
				throw ImageCacheError.mustBeBoolLiteral
			}
			useSwiftData = tokenKind == .keyword(.true)
		} else {
			useSwiftData = false
		}
		
		let transientMacro = useSwiftData ? "@Transient " : ""
		
		return ["""
		\(raw: transientMacro)private var \(raw: hashIdentifier): Int = 0
		\(raw: transientMacro)private var \(raw: cacheIdentifier): Image?
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
