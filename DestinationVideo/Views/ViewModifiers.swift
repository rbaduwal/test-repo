/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom view modifiers that the app defines.
*/

import SwiftUI

#if os(visionOS)
extension View {
    // A custom modifier in visionOS that manages the presentation and dismissal of the app's immersive space.
    func immersionManager() -> some View {
        self.modifier(ImmersiveSpacePresentationModifier())
    }
}
#else
extension View {
    // Only used in iOS and tvOS for full-screen modal presentation.
    func fullScreenCoverPlayer() -> some View {
        self.modifier(FullScreenCoverModifier())
    }
}
#endif

#if os(visionOS)
private struct ImmersiveSpacePresentationModifier: ViewModifier {
    
    @Environment(Immersion.self) private var immersion
    @Environment(PlayerModel.self) private var playerModel
    
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    /// The current phase for the scene, which can be active, inactive, or background.
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View {
        content
            .onChange(of: immersion.navigationPath) {
                Task {
                    // The selection path becomes empty when the user returns to the main library window.
                    if immersion.navigationPath.isEmpty {
                        if immersion.isImmersive {
                            // Dismiss the space and return the user to their real-world space.
                            await dismissSpace()
                            immersion.isImmersive = false
                        }
                    } else {
                        guard !immersion.isImmersive else { return }
                        // The navigationPath has one video, or is empty.
                        guard let video = immersion.navigationPath.first else { fatalError() }
                        // Await the request to open the destination and set the state accordingly.
                        switch await openSpace(value: video.destination) {
                        case .opened: immersion.isImmersive = true
                        default: immersion.isImmersive = false
                        }
                    }
                }
            }
            // Close the space and unload media when the user backgrounds the app.
            .onChange(of: playerModel.currentItem) { _, newVideo in
                Task {
                    if let newVideo {
                        if !immersion.isImmersive {
                            // Await the request to open the destination and set the state accordingly.
                            switch await openSpace(value: newVideo.destination) {
                            case .opened: immersion.isImmersive = true
                            default: immersion.isImmersive = false
                            }
                        }
                    } else {
                        // If on the main screen while currently displaying an immersive space, dismiss it.
                        if immersion.navigationPath.isEmpty, immersion.isImmersive {
                            await dismissSpace()
                            immersion.isImmersive = false
                        }
                    }
                }
            }
            // The system dismisses the immersive space when the app is backgrounded.
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    immersion.isImmersive = false
                }
            }
    }
}
#endif

private struct FullScreenCoverModifier: ViewModifier {
    
    @Environment(PlayerModel.self) private var player
    @State private var isPresentingPlayer = false
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresentingPlayer) {
                PlayerView()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.reset()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            // Observe the player's presentation property.
            .onChange(of: player.presentation, { _, newPresentation in
                isPresentingPlayer = newPresentation == .fullWindow
            })
    }
}

