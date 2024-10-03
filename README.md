# ImageCache

ImageCache is a Swift Macro designed to ease the use of the SwiftUI `Image` Type when working with SwiftData. SwiftData does not have native support to persist SwiftUI `Image`s. In order to persist an Image, you must use a `Data` object and convert that to a SwiftUI `Image` every time you want to use it. But this conversion process is computationally heavy, which is why you should somehow cache to `Image`. This macro handles all of that for you, be generating a computed property that resembles your `Data` object and only re-converts it, when the underlying `Data` changes.

## Installation
In Xcode click on 'File' in the menu bar, then select 'Add package dependencies...' and enter [this repositories URL](git@github.com:qhilipp/ImageCache.git) into the top-right text field and click 'Copy Dependency'. This should be all for the installation. 

## Definition
```swift
@attached(peer, names: arbitrary)
public macro ImageCache() = #externalMacro(module: "ImageCacheMacros", type: "ImageCacheMacro")
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

## Restrictions
Since this macro creates multiple new variables for handeling the caching and the final image variable, which are appropriately named, the definition must state that this macro can create 'arbitraty' names, which restricts the macro to not being used at a global level. But since this macro is intended to be used with SwiftData, you will use it inside classes anyways. Also peer macros, which the `@ImageCache` is, can only be applied to single variable declarations, meaning that declarations like
```swift
@ImageCache
var profilePictureData, bannerData: Data?
```
will not compile.

## References
[Swift](https://developer.apple.com/documentation/swift/)
- [Data class](https://developer.apple.com/documentation/foundation/data)

[SwiftUI](https://developer.apple.com/documentation/swiftui/)
 - [Image struct](https://developer.apple.com/documentation/swiftui/image)
 
[SwiftData](https://developer.apple.com/documentation/swiftdata)
