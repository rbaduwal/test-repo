/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that stores data about the state of immersion in the app.
*/

import Foundation

@Observable class Immersion {
    /// A Boolean value that indicates whether the app is presenting an immersive space.
    var isImmersive = false
    /// The navigation path of the app.
    /// The app presents an immersive space when you select a video from the main screen.
    var navigationPath = [Video]()
    
}
