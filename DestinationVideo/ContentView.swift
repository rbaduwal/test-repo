/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the app's user interface.
*/

import SwiftUI

// The app uses `LibraryView` as its main UI.
struct ContentView: View {
    
    /// The app's player model.
    @Environment(PlayerModel.self) private var player
    
    var body: some View {
        #if os(visionOS)
        Group {
            switch player.presentation {
            case .fullWindow:
                // Present the player full window and begin playback.
                PlayerView()
                    .onAppear {
                        player.play()
                    }
            default:
                // Show the app's content library by default.
                LibraryView()
            }
        }
        // A custom modifier that manages the presentation and dismissal of the app's immersive space.
        .immersionManager()
        #else
        LibraryView()
            // A custom modifier that shows the player in a fullscreen modal presentation in iOS and tvOS.
            .fullScreenCoverPlayer()
        #endif
    }
}

#Preview {
    ContentView()
        .environment(PlayerModel())
        .environment(VideoLibrary())
        .environment(Immersion())
}
