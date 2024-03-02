/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI
import os

@main
struct DestinationVideo: App {

    /// An object that controls the video playback behavior.
    @State private var player = PlayerModel()
    /// An object that manages the library of video content.
    @State private var library = VideoLibrary()
    /// An object that stores the app's immersion state.
    @State private var immersion = Immersion()

#if os(visionOS)
    /// The content brightness to apply to the immersive space.
    @State private var contentBrightness = ImmersiveContentBrightness.automatic
#endif
    
    var body: some Scene {
        // The app's primary content window.
        WindowGroup {
            ContentView()
                .environment(player)
                .environment(library)
                .environment(immersion)
            #if !os(visionOS)
                // Use a dark color scheme on supported platforms.
                .preferredColorScheme(.dark)
                .tint(.white)
            #endif
        }
        #if os(visionOS)
        // Defines an immersive space to present a destination in which to watch the video.
        ImmersiveSpace(for: Destination.self) { $destination in
            if let destination {
                DestinationView(destination)
                    .environment(player)
                    .onAppear {
                        contentBrightness = destination.contentBrightness
                    }
            }
        }
        // Set the content brightness for the immersive space.
        .immersiveContentBrightness(contentBrightness)
        // Set the immersion style to progressive, so the user can use the crown to dial in their experience.
        .immersionStyle(selection: .constant(.progressive), in: .progressive)
        #endif
    }
}

/// A global logger for the app.
let logger = Logger()
