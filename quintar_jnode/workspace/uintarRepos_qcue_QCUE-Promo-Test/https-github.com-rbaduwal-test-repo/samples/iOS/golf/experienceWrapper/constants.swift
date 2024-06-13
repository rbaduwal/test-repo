import Foundation

// Tabs
let STR_SCHEDULE = "Schedule"

// PlayerTable
let playerTableViewHeight = 27.0

public struct defaultMessage {
   static var trackingFailedErrorMessage: String = "Uh oh, something's not right. We are working on it, please standby."
   static var messageOnTrackingRequested: String = "Point phone towards hole and hold steady to connect"
   static var connectingMessage = "One moment...\nWe are lining up our shot."
   static var messageOnConnectedToHole = "Point towards hole and hold steady"
   static var registrationFailedErrorMessage: String = "It's not you, it's us. Attempting to line up our shot again, please stand by."
   static let userAwayFromHole: String = "You are away from the hole."
   static var networkNotAvailableMessage = "Internet connection is not available, lining up our shot will be possible once the connection is restored."
   static var groupPlayNotificationTitle = "are ready to view"
   static let upcomingGameMessage = "We’re excited too!"
   static let upcomingGameInfo = "Be sure to try again during live tournament play."
   static let deniedLocationPermission = "Please enable the location permission."
   static let instructionToRotatePhone = "Rotate phone to begin."
   static let messageOnNoHole: String = "Currently no players on hole"
   static let holeConfirmationMessage = "Would you like to connect \n to Hole "
}

public enum messageType: String {
   case trackingFailedErrorMessage = "trackingFailedErrorMessage"
   case messageOnTrackingRequested = "messageOnTrackingRequested"
   case connectingMessage = "connectingMessage"
   case instructionToRotatePhone = "instructionToRotatePhone"
   case messageOnConnectedToHole = "messageOnConnectedToHole"
   case registrationFailedErrorMessage = "registrationFailedErrorMessage"
   case userAwayFromHole = "userAwayFromHole"
   case groupPlayNotificationTitle = "groupPlayNotificationTitle"
   case upcomingGameMessage = "upcomingGameMessage"
   case upcomingGameInfo = "upcomingGameInfo"
   case networkNotAvailableMessage = "networkNotAvailableMessage"
   case deniedLocationPermission = "deniedLocationPermission"
   case messageOnNoHole = "messageOnNoHole"
   case holeConfirmationMessage = "holeConfirmationMessage"
}

public enum userDefaultKeys : String, CaseIterable {
   case testModeEnabledStatus = "testModeEnabledStatus"
   case outlinesEnabledStatus = "outlinesEnabledStatus"
   case showDebugLogsStatus = "showDebugLogsStatus"
   case disableGPS = "Disable GPS"
   case enableInAppNotificationsStatus = "enableInAppNotificationsStatus"
}

public class configurableText {
   static let instance = configurableText()
   
   var messages: [String: Any] = [:]
   var defaultMessages: [String: Any] = [:]
   
   init() {
      defaultMessages = [
         messageType.trackingFailedErrorMessage.rawValue: defaultMessage.trackingFailedErrorMessage,
         messageType.messageOnTrackingRequested.rawValue: defaultMessage.messageOnTrackingRequested,
         messageType.instructionToRotatePhone.rawValue: defaultMessage.instructionToRotatePhone,
         messageType.connectingMessage.rawValue: defaultMessage.connectingMessage,
         messageType.messageOnConnectedToHole.rawValue: defaultMessage.messageOnConnectedToHole,
         messageType.registrationFailedErrorMessage.rawValue: defaultMessage.registrationFailedErrorMessage,
         messageType.userAwayFromHole.rawValue: defaultMessage.userAwayFromHole,
         messageType.deniedLocationPermission.rawValue: defaultMessage.deniedLocationPermission,
         messageType.groupPlayNotificationTitle.rawValue: defaultMessage.groupPlayNotificationTitle,
         messageType.networkNotAvailableMessage.rawValue: defaultMessage.networkNotAvailableMessage,
         messageType.upcomingGameMessage.rawValue: defaultMessage.upcomingGameMessage,
         messageType.upcomingGameInfo.rawValue: defaultMessage.upcomingGameInfo,
         messageType.messageOnNoHole.rawValue: defaultMessage.messageOnNoHole,
         messageType.holeConfirmationMessage.rawValue: defaultMessage.holeConfirmationMessage
      ]
   }
   func setARUIViewConfig(aruiConfig: [String:Any]) {
      if let aruiViewData = aruiConfig["arUiView"] as? [String:Any] {
         if let experienceData = aruiViewData["experiences"] as? [[String:Any]] {
            for messageData in experienceData {
               if let messageValues = messageData["messages"] as? [String:Any] {
                  self.messages = messageValues
               }
            }
         }
      }
   }
   public func getText(id: messageType) -> String {
      return self.messages[id.rawValue] as? String ?? (self.defaultMessages[id.rawValue] as? String ?? "")
   }
}
