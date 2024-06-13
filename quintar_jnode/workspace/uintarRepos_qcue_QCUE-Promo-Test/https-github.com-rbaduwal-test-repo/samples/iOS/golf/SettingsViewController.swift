import UIKit
import Q_ui

class SettingsViewController: UIViewController {
   @IBOutlet weak var testModeSwitch: UISwitch!
   @IBOutlet weak var showOutlineSwitch: UISwitch!
   @IBOutlet weak var debugInfoSwitch: UISwitch!
   @IBOutlet weak var disableGPSSwitch: UISwitch!
   @IBOutlet weak var inAppNotificationSwitch: UISwitch!
   @IBAction func didTapShowOutlineSwitch(_ sender: Any) {
      outlinesEnabled = !outlinesEnabled
   }
   @IBAction func didTapTestModeSwitch(_ sender: Any) {
      testModeEnabled = !testModeEnabled
   }
   @IBAction func didTapDebugInfoSwitch(_ sender: Any) {
      debugLogsEnabled = !debugLogsEnabled
   }
   @IBAction func didTapDisableGPSSwitch(_ sender: Any) {
      gpsDisabled = !gpsDisabled
   }
   
   @IBAction func didTapInAppNotificationsSwitch(_ sender: Any) {
      inAppNotificationsEnabled = !inAppNotificationsEnabled
   }
   public var outlinesEnabled: Bool {
      get { userInfo.instance.userDefault(for: .outlinesEnabledStatus) }
      set {
         userInfo.instance.userDefault(for: .outlinesEnabledStatus, value: newValue)
         SettingsViewController.apply()
      }
   }
   public var testModeEnabled: Bool {
      get { userInfo.instance.userDefault(for: .testModeEnabledStatus) }
      set {
         userInfo.instance.userDefault(for: .testModeEnabledStatus, value: newValue)
         SettingsViewController.apply()
      }
   }
   public var inAppNotificationsEnabled: Bool {
      get { userInfo.instance.userDefault(for: .enableInAppNotificationsStatus) }
      set {
         userInfo.instance.userDefault(for: .enableInAppNotificationsStatus, value: newValue)
         SettingsViewController.apply()
      }
   }
   public var debugLogsEnabled: Bool {
      get { userInfo.instance.userDefault(for: .showDebugLogsStatus) }
      set {
         userInfo.instance.userDefault(for: .showDebugLogsStatus, value: newValue)
         SettingsViewController.apply()
      }
   }
   public var gpsDisabled: Bool {
      get { userInfo.instance.userDefault(for: .disableGPS) }
      set {
         userInfo.instance.userDefault(for: .disableGPS, value: newValue)
         SettingsViewController.apply()
      }
   }
   public static func apply() {
      // Only do stuff if we have an experience wrapper
      if let xw = experienceWrapper.instance.experience as? golfVenueExperienceWrapper {
         var testModeValues = [venue.VENUE_TESTS]()
         for item in userDefaultKeys.allCases {
            switch item {
               case .outlinesEnabledStatus:
                  if userInfo.instance.userDefault(for: item) {
                     testModeValues.append(.OUTLINES)
                  }
               case .testModeEnabledStatus:
                  if userInfo.instance.userDefault(for: item) {
                     testModeValues.append(.TEST_IMAGE)
                  }
                  DispatchQueue.main.async {
                     xw.stopTracking()
                     xw.onTrackingReset()
                  }
               case .showDebugLogsStatus:
                  xw.enableDebugLabel = userInfo.instance.userDefault(for: item)
               case .disableGPS:
                  break
               case .enableInAppNotificationsStatus:
                  xw.enableInAppNotifications = userInfo.instance.userDefault(for: item)
            }
         }
         xw.enableTestModes( testModeValues )
      }
   }

   override func viewDidLoad() {
      super.viewDidLoad()
      testModeSwitch.isOn = testModeEnabled
      showOutlineSwitch.isOn = outlinesEnabled
      debugInfoSwitch.isOn = debugLogsEnabled
      disableGPSSwitch.isOn = gpsDisabled
      inAppNotificationSwitch.isOn = inAppNotificationsEnabled
   }
}
