import UIKit

public extension Notification.Name {
   static let onTrackingRequested = Notification.Name("onTrackingRequested")
   static let onTrackingUpdated = Notification.Name("onTrackingUpdated")
   static let modelDownloadingCompleted = Notification.Name("modelDownloadingCompleted")
   static let onModelPlacementMode = Notification.Name("onModelPlacementMode")
   static let onModelPlacementModeCompleted = Notification.Name("onModelPlacementModeCompleted")
   static let deviceState = Notification.Name("deviceState")
}
