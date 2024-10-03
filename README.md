# ImageCache

ImageCache is a Swift Macro designed to ease the use of the SwiftUI `Image` Type when working with SwiftData. SwiftData does not have native support to persist SwiftUI `Image`s. In order to persist an Image, you must use a `Data` object and convert that to a SwiftUI `Image` every time you want to use it. But this conversion process is computationally heavy, which is why you should somehow cache to `Image`. This macro handles all of that for you, be generating a computed property that resembles your `Data` object and only re-converts it, when the underlying `Data` changes.

## Installation
In Xcode click on 'File' in the menu bar, then select 'Add package dependencies...' and enter [this repositories URL](git@github.com:qhilipp/ImageCache.git) into the top-right text field and click 'Copy Dependency'. This should be all for the installation. 

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
