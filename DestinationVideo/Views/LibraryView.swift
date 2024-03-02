/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the list of videos the library contains.
*/
import SwiftUI

/// A view that presents the app's content library.
///
/// This view provides the app's main user interface. It displays two
/// horizontally scrolling rows of videos. The top row displays full-sized
/// cards that represent the Featured videos in the app. The bottom row
/// displays videos that the user adds to their Up Next queue.
///
struct LibraryView: View {
    
    @Environment(Immersion.self) private var immersion
    @Environment(PlayerModel.self) private var model
    @Environment(VideoLibrary.self) private var library

    var body: some View {
        @Bindable var immersion = immersion
        NavigationStack(path: $immersion.navigationPath) {
            // Wrap the content in a vertically scrolling view.
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: verticalPadding) {
                    // Displays the Destination Video logo image.
                    Image("dv_logo")
                        .resizable()
                        .scaledToFit()
                        .padding(.leading, outerPadding)
                        .padding(.bottom, isMobile ? 0 : 8)
                        .frame(height: logoHeight)
                        .accessibilityHidden(true)
                    
                    // Displays a horizontally scrolling list of Featured videos.
                    VideoListView(title: "Featured",
                                  videos: library.videos,
                                  cardStyle: .full,
                                  cardSpacing: horizontalSpacing)
                    
                    // Displays a horizontally scrolling list of videos in the user's Up Next queue.
                    VideoListView(title: "Up Next",
                                  videos: library.upNext,
                                  cardStyle: .upNext,
                                  cardSpacing: horizontalSpacing)
                }
                .padding([.top, .bottom], verticalPadding)
                .navigationDestination(for: Video.self) { video in
                    DetailView(video: video)
                        .navigationTitle(video.title)
                        .navigationBarHidden(isTV)
                }
            }
            #if os(tvOS)
            .ignoresSafeArea()
            #endif
        }
    }

    // MARK: - Platform-specific metrics.
    
    /// The vertical padding between views.
    var verticalPadding: Double {
        valueFor(iOS: 30, tvOS: 40, visionOS: 30)
    }
    
    var outerPadding: Double {
        valueFor(iOS: 20, tvOS: 50, visionOS: 30)
    }
    
    var horizontalSpacing: Double {
        valueFor(iOS: 20, tvOS: 80, visionOS: 30)
    }
    
    var logoHeight: Double {
        valueFor(iOS: 24, tvOS: 60, visionOS: 34)
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .environment(PlayerModel())
    .environment(VideoLibrary())
    .environment(Immersion())
}
