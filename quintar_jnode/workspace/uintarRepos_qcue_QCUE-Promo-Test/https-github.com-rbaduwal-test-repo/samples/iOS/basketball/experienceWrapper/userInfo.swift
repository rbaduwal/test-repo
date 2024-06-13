import Q
import Q_ui

// Keeps track of persistent user selections, and provides a user analytics hook
open class userInfo {
   // Singleton
   static let instance = userInfo()
   private init()
   {
      // Handle log entries
      experienceWrapper.instance.logEntryAdded = self.onLogEntryAdded
   }
   
   // Set/get user defaults
//   func userDefault(for setting: userDefaultKeys, value: Bool ) {
//      UserDefaults.standard.set(value, forKey: setting.rawValue)
//   }
//   func userDefault(for setting: userDefaultKeys) -> Bool {
//      UserDefaults.standard.bool(forKey: setting.rawValue)
//   }
   func registerDefaults() {
//      UserDefaults.standard.register(defaults: [
//         userDefaultKeys.outlinesEnabledStatus.rawValue: true,
//         userDefaultKeys.testModeEnabledStatus.rawValue: true,
//         userDefaultKeys.showDebugLogsStatus.rawValue: true,
//         userDefaultKeys.disableGPS.rawValue: false,
//         userDefaultKeys.enableInAppNotificationsStatus.rawValue: true
//      ])
   }
   
   // Analytics and debug view handler
   public func onLogEntryAdded(severity: Q.LOG_SEVERITY, msg:  String, userInfo: [AnyHashable:Any]?) {
      let logText = "\(severity): \(msg)"
      switch ( severity )
      {
//         case .DEBUG, .ERROR, .WARNING, .INFO:
//             // Send to our debug UI and the debug console
//            DispatchQueue.main.async {
//               experienceWrapper.golf?.screenView?.debugInfo.text = logText
//            }
//         case .ANALYTICS:
//            // TODO: Handle analytics here. `userInfo` has a dictionary of useful values.
//            break
         default: print(logText)
      }
   }
}
