/// A macro to ease the use of images using SwiftData, by automatically providing a SwiftUI `Image`.
///
/// Annotate a variable of type `Data?` with the `@ImageCache` to macro to get a computed property that resembles that `Data?` as a SwiftUI `Image`. The data variable must have a name ending with 'Data'. For example
///
/// ```swift
/// @ImageCache
/// var profilePictureData: Data?
/// ```
/// will expand to
///
/// ```swift
/// var profilePictureData: Data?
/// private var profilePictureHash: Int = 0
///	private var profilePictureCache: Image?
///	var profilePicture: Image? {
///		get {
///			if profilePictureData.hashValue != profilePictureHash,
///				let profilePictureData,
///				let uiImage = UIImage(data: profilePictureData)
///			{
///				profilePictureCache = Image(uiImage: uiImage)
///				profilePictureHash = profilePictureData.hashValue
///			}
///			return profilePictureCache
///		}
///	}
/// ```
///	The implementation will be different depending on the target platform, macOS will use `NSImage` instead of `UIImage`.
@attached(peer, names: arbitrary)
public macro ImageCache(useSwiftData: Bool = true) = #externalMacro(module: "ImageCacheMacros", type: "ImageCacheMacro")
