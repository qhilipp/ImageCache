# ImageCache
ImageCache is a Swift Macro designed to ease the use of the SwiftUI `Image` Type when working with SwiftData. SwiftData does not have native support to persist SwiftUI `Image`s. In order to persist an Image, you must use a `Data` object and convert that to a SwiftUI `Image` every time you want to use it. But this conversion process is computationally heavy, which is why you should somehow cache to `Image`. This macro handles all of that for you, be generating a computed property that resembles your `Data` object and only re-converts it, when the underlying `Data` changes.

## Installation
In Xcode click on 'File' in the menu bar, then select 'Add package dependencies...' and enter [this repositories URL](git@github.com:qhilipp/ImageCache.git) into the top-right text field and click 'Copy Dependency'. This should be all for the installation. 

## Definition
```swift
@attached(peer, names: arbitrary)
public macro ImageCache(useSwiftData: Bool = true) = #externalMacro(module: "ImageCacheMacros", type: "ImageCacheMacro")
```

## Usage
Once the package is installed, just
```swift
import ImageCache
```
at the start of each file, where you want to use the macro. Since SwiftData can only handle `Data` objects as representation for images, create a variable of type `Data?` and choose a name that ends with 'Data'. Then just attach the `@ImageCache` macro to that variable. For example
```swift
@ImageCache
var profilePictureData: Data?
```

## Parameters
The only parameter is the `useSwiftData: Bool` which is `true` by default. When this parameter is set to true, SwiftData must also be imported, because it adds the [`@Transient`](https://developer.apple.com/documentation/swiftdata/transient()) macro to the helper variables, that handle the caching. Since this macro is intended to be used with SwiftData, you probably want to leave this to the default value, however for some test porpuses or temporary usages where you do not need persistent storage, you could set this to `false` in order to not have to import SwiftData.

## Restrictions and compatibility
Since this macro creates multiple new variables for handeling the caching and the final image variable, which are appropriately named, the definition must state that this macro can create 'arbitraty' names, which restricts the macro to not being used at a global level. But since this macro is intended to be used with SwiftData, you will use it inside classes anyways. 

Also peer macros, which the `@ImageCache` is, can only be applied to single variable declarations, meaning that declarations like
```swift
@ImageCache
var profilePictureData, bannerData: Data?
```
will not compile.

Since there is no direct way to create an `Image` from a `Data` object, the macro first creates a `UIImage` or `NSImage` depending on the platform you use. This also means, that this macro only works on platforms, that support either UIKit or AppKit, which should cover all major platforms (iOS, iPadOS and macOS), but as of now watchOS, tvOS and visionOS are not supported.

## Important Notes
When you use `@ImageCache` to use images using SwiftData, which you probably do, then you should also attach `@Attribute(.externalStorage) to the `Data?` object, the reason for this is explained in [this article](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-store-swiftdata-attributes-in-an-external-file).

## References
[Swift](https://developer.apple.com/documentation/swift/)
- [Data class](https://developer.apple.com/documentation/foundation/data)

[SwiftUI](https://developer.apple.com/documentation/swiftui/)
 - [Image struct](https://developer.apple.com/documentation/swiftui/image)
 
[SwiftData](https://developer.apple.com/documentation/swiftdata)
 - [Transient macro](https://developer.apple.com/documentation/swiftdata/transient())
