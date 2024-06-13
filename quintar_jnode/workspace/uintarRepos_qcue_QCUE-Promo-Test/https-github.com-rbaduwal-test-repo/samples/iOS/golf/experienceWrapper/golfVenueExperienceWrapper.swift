import UIKit
import Q_ui
import Q
import CoreLocation

public struct decodedGeofenceData: Decodable {
   public let fops: [fop]?
   public let gr: Double?
   public let lat: Double?
   public let long: Double?
   public struct fop: Decodable {
      public let id: String
      public let lat: Double?
      public let long: Double?
      public let fr: Double?
   }
}

open class golfVenueExperienceWrapper: Q_ui.golfVenue {
   public private(set) var screenView: experienceView?
   public var enableDebugLabel: Bool {
      get { return screenView?.enableDebugLabel ?? false }
      set { screenView?.enableDebugLabel = newValue }
   }
   public var userIsAtCourse: Bool = true
   public var enableInAppNotifications: Bool {
      get { return screenView?.enableInAppNotifications ?? false }
      set { screenView?.enableInAppNotifications = newValue }
   }
   public var enableOobeView: Bool {
      get { return screenView?.enableOobeView ?? false }
      set {
         screenView?.enableOobeView = newValue
         DispatchQueue.main.async {
            if newValue {
               self.hide2DElementsForOOBE()
            } else {
               self.screenView?.oobeView.isHidden = true
               self.screenView?.pgaLogo.isHidden = false
               self.screenView?.connectView.isHidden = false
            }
         }
      }
   }
   private var trackingSucceededAtLeastOnce = false
   private var wasDeviceReadyDuringTracking = false
   private var geofencingFailedDuringTracking = true
   private var deviceNotReadyTime = Date.now
   private var trackingFailureCount: Int = 0
   private var timeDifference: Double = 0.0
   private var locationManager = CLLocationManager()
   private var meterToFeet = 3.28084
   private var geofenceData: decodedGeofenceData? = nil
   private var geofenceTimer: Timer? = nil

   public override func onInit() {
      super.onInit()

      guard let viewNib = UINib.fromSdkBundle("experienceView") else { return }
      self.screenView = viewNib.instantiate(withOwner: nil, options: nil).first as? experienceView
      self.screenView?.enableDebugLabel = false
      self.screenView?.connectButton.addTarget(self, action: #selector(tapToBeginAction), for: .touchUpInside)
      
      // Set our venue object as the view model
      self.screenView?.viewModel = self
      
      // Set our 2D experience for the SDK, since it only provides the 3D stuff
      self.arViewController.screenView = screenView
      
      // Grab the geo-fencing configuration, if it exists.
      // Start a timer to periodically check the geo-fence status.
      do {
         if let geofence = self.arViewController.arUiConfig.geofenceData {
            let jsonData = try JSONSerialization.data(withJSONObject: geofence, options: .prettyPrinted)
            self.geofenceData = try JSONDecoder().decode(decodedGeofenceData.self, from: jsonData)
         }
      } catch let e {
         log.instance.push(.ERROR, msg: "\(e)")
      }
      startGeofenceTimer()
      
      // Here's where you can add some geo-fencing logic
      self.geofenceCallback = { fop in
         return self.isUserAtCourse(for: fop)
      }

      // This is a good spot to turn on microphone access, if needed
      self.arViewController.arUiConfig.microphoneEnabled = false
   
      // Enabling test mode is ONLY for non-production builds (or you can hide it behind an Easter egg).
      // Test mode allows us to:
      //  - use test images on a real connect server
      //  - show outlines
      // You can pass in an empty array [] to disable all tests.
      // Tests also depend on appropriate values in the config files.
      self.enableTestModes( [.OUTLINES, .TEST_IMAGE] )
      
      NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
   }
   public override func onTrackingUpdated(trackingStatus: trackingUpdate) {
      super.onTrackingUpdated(trackingStatus: trackingStatus)
      
      var lat = 0.0
      var lon = 0.0
      var latlonAccuracy = 0.0
      if let sceneIntrinsic = trackingStatus.sceneIntrinsic {
         lat = sceneIntrinsic.deviceTrackingState.location.lat
         lon = sceneIntrinsic.deviceTrackingState.location.lon
         latlonAccuracy = sceneIntrinsic.deviceTrackingState.location.latlonAccuracy
      }
      DispatchQueue.main.async {
         switch trackingStatus.error {
            case .NONE:
               self.screenView?.connectView.isHidden = true
               self.screenView?.connectingView.isHidden = true
               self.screenView?.backgroundColor = .clear
               self.screenView?.mainContainerView.isHidden = false
               self.screenView?.playerContainerView.isHidden = false
               self.trackingSucceededAtLeastOnce = true
               self.wasDeviceReadyDuringTracking = true
               self.geofencingFailedDuringTracking = true
               Q.log.instance.push(.INFO, msg: "Registration successfull\n\(trackingStatus)" )
               Q.log.instance.push(.ANALYTICS, msg: "onRegistrationSuccess", userInfo: ["holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1,"lat":lat, "lon":lon, "latlonAccuracy":latlonAccuracy])
            case .TRACKING_RESET:
               Q.log.instance.push(.WARNING, msg: "Tracking was reset" )
               Q.log.instance.push(.ANALYTICS, msg: "onRegistrationFailureFromServer", userInfo: ["holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1, "lat":lat, "lon":lon, "latlonAccuracy":latlonAccuracy])
               // If device was ready during tracking and we were already successfully tracking, ignore the server error
               if self.wasDeviceReadyDuringTracking && self.trackingSucceededAtLeastOnce {
                  return
               }
               
               DispatchQueue.main.async {
                  self.resetTrackingUpdatesToConnectView()
               }
            case .LOCATION:
               Q.log.instance.push(.WARNING, msg: "User is not at the course." )
               Q.log.instance.push(.ANALYTICS, msg: "gpsTooFarFromSite", userInfo: ["holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1, "lat":lat, "lon":lon, "latlonAccuracy":latlonAccuracy])
               self.wasDeviceReadyDuringTracking = false
               self.geofencingFailedDuringTracking = false
               
               DispatchQueue.main.async {
                  self.resetTrackingUpdatesToConnectView()
               }
            case .TRACKING_DEVICE_NOT_READY:
               Q.log.instance.push(.WARNING, msg: "Device is not ready for tracking" )
               Q.log.instance.push(.ANALYTICS, msg: "onRegistrationConditionNotMet", userInfo: ["holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1, "lat":lat, "lon":lon, "latlonAccuracy":latlonAccuracy])
               self.wasDeviceReadyDuringTracking = false
               self.geofencingFailedDuringTracking = true
               
               DispatchQueue.main.async {
                  self.resetTrackingUpdatesToConnectView()
               }
            case .HTTP:
               Q.log.instance.push(.ANALYTICS, msg: "onRegistrationFailureFromServer", userInfo: ["holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1, "lat":lat, "lon":lon, "latlonAccuracy":latlonAccuracy])
               self.screenView?.debugInfo.text = trackingStatus.registrationError.debugDescription
               DispatchQueue.main.async {
                  self.resetTrackingUpdatesToConnectView()
            }
            default:
               Q.log.instance.push(.ANALYTICS, msg: "onRegistrationFailureForUnknownReason", userInfo: ["holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1, "lat":lat, "lon":lon, "latlonAccuracy":latlonAccuracy])
               DispatchQueue.main.async {
                  self.resetTrackingUpdatesToConnectView()
               }
               Q.log.instance.push(.ERROR, msg: trackingStatus.errorMsg )
               break
         }
      }
   }
   public func isUserAtCourse(for fop:String? = nil) -> ( Bool, String ) {
      if ( userInfo.instance.userDefault(for: userDefaultKeys.disableGPS) ) {
         return ( true, "" )
      } else {
         switch locationManager.authorizationStatus {
            case .restricted, .denied:
               return ( false, configurableText.instance.getText(id: messageType.deniedLocationPermission) )
            default:
               let currentLoc: CLLocation? = locationManager.location
               if let geofenceData = experienceWrapper.golf?.geofenceData {
                  // If FOP is empty, then assume we are to check the course-level geofencing, not the FOP-level geofencing.
                  // This is usually done once on startup, whereas FOP geofencing is checked more regularly.
                  if fop == "" {
                     if let tournamentLatitude = geofenceData.lat, let tournamentLongitude = geofenceData.long, let radius = geofenceData.gr {
                        let destinationLocation = CLLocation(latitude: tournamentLatitude, longitude: tournamentLongitude)
                        if let distance = currentLoc?.distance(from: destinationLocation) {
                           if ((distance * Double(meterToFeet)) < radius ) {
                              return ( true, "" )
                           } else {
                              return ( false, configurableText.instance.getText(id: messageType.userAwayFromHole) )
                           }
                        } else {
                           return ( true, "" )
                        }
                     }
                  } else {
                     if let fops = geofenceData.fops {
                        if let currentFop = fops.first(where: { fopDetails in
                           fopDetails.id == fop
                        }), let latitude = currentFop.lat, let longitude = currentFop.long, let radius = currentFop.fr {
                           let destinationLocation = CLLocation(latitude: latitude, longitude: longitude)
                           if let distance = currentLoc?.distance(from: destinationLocation) {
                              if ((distance * Double(meterToFeet)) < radius ) {
                                 return ( true, "" )
                              } else {
                                 return ( false, configurableText.instance.getText(id: messageType.userAwayFromHole) )
                              }
                           } else {
                              return ( true, "" )
                           }
                        }
                     }
                  }
               }
            return ( true, "" )
         }
      }
   }
   public func onTrackingReset() {
      self.screenView?.connectingView.isHidden = true
      self.screenView?.connectView.isHidden = false
      self.screenView?.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.35)
      self.screenView?.mainContainerView.isHidden = true
      trackingSucceededAtLeastOnce = false
      self.screenView?.debugInfo.text = ""
      self.screenView?.togglePlayerEntitiesVisibilityView.isHidden = true
   }
   public func hide2DElementsForOOBE() {
      self.screenView?.errorAlertView.isHidden = true
      self.screenView?.connectView.isHidden = true
      self.screenView?.connectingView.isHidden = true
      self.screenView?.pgaLogo.isHidden = true
   }

   private func showErrorAlertView() {
      var errorText:String = String()
      if self.wasDeviceReadyDuringTracking  {
         // If device was ready it will be issue with the connection or server
         errorText = configurableText.instance.getText(id: messageType.registrationFailedErrorMessage)
      } else {
         if !geofencingFailedDuringTracking {
            errorText = configurableText.instance.getText(id: messageType.userAwayFromHole)
         } else {
            onTrackingReset()
            return
         }
      }
      self.screenView?.errorAlertView.setErrorTitleAndText(titleText: errorText, infoText: "")
      self.screenView?.errorAlertView.isHidden = false
      self.screenView?.connectView.isHidden = true
   }   
   private func startGeofenceTimer(){
      stopGeofenceTimer()
      
      DispatchQueue.main.async {
         self.geofenceTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.experienceConfig?.geofencingTimerInterval ?? 2), target: self, selector: #selector(self.startGeofencing), userInfo: nil, repeats: true)
      }
   }
   private func stopGeofenceTimer() {
      if geofenceTimer != nil {
         geofenceTimer?.invalidate()
         geofenceTimer = nil
      }
   }
   private func resetTrackingUpdatesToConnectView() {
      self.trackingFailureCount = self.trackingFailureCount + 1
      if self.trackingFailureCount > self.experienceConfig?.maxTrackingFailure ?? 3 {
         self.onTrackingReset()
         self.showErrorAlertView()
         self.stopTracking()
         self.trackingFailureCount = 0
      }
   }
   @objc private func appMovedToBackground() {
      DispatchQueue.global(qos: .background).async {
         self.onAppSuspend()
      }
      timeDifference = Date.now.timeIntervalSince1970
   }
   @objc private func appMovedToForeground() {
      DispatchQueue.global(qos: .background).async {
         self.onAppResume()
      }
      if (Date.now.timeIntervalSince1970 - timeDifference) > 5 {
         self.onTrackingReset()
         self.stopTracking()
      }
   }
   @objc private func startGeofencing() {
      if let fop = self.fop {
         let ( _, _ ) = self.geofenceCallback(fop)
         self.screenView?.updateConnectUI()
      }
   }
   @objc private func onConnectingToTrackingServer(_ notification: Notification) {
      self.wasDeviceReadyDuringTracking = true
      DispatchQueue.main.async {
         if !self.trackingSucceededAtLeastOnce {
            self.screenView?.connectView.isHidden = true
            self.screenView?.connectingView.isHidden = false
            self.screenView?.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.35)
            self.screenView?.mainContainerView.isHidden = true
            Q.log.instance.push(.INFO, msg: "Registration is ongoing")
         }
      }
      deviceNotReadyTime = Date.now
   }
   @objc private func tapToBeginAction() {
      if let tracker = arViewController.tracker {
         if !tracker.isTracking {
            screenView?.connectView.isHidden = true
            screenView?.connectingView.isHidden = false
            
            // Start tracking
            startTracking(useLocationServices: false)
            screenView?.reloadPlayerData()
         }
      }
   }   
}

// Convenient way of accessing the XW singleton as the specific type we care about
extension experienceWrapper {
   static var golf: golfVenueExperienceWrapper? {
      return experienceWrapper.instance.experience as? golfVenueExperienceWrapper
   }
}
