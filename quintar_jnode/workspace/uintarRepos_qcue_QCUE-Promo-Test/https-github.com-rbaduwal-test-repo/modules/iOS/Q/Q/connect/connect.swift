public class connect {
   
   public private(set) var config: connectConfig
   public private(set) var isTracking: Bool = false
   public private(set) var viewPosition: SIMD3<Double> = [0,0,0]
   public private(set) var viewDirection: SIMD3<Double> = [0,0,0]
   private var isRegistrationInProgress: Bool = false
   private var trackingTimeInterval: Int = 1
   private var trackingTimer: Timer?
   private var numConsecutiveFails: Int = 0
   private var lastTrackingResult: trackingUpdate? = nil
   private let downloader: httpDownloader
   
   // Optional callback for when a new tracking update has been requested.
   // This is for significant tracking updates, not every frame
   public var trackingRequested: (()->())? = nil
   
   // Optional callback for when tracking has been updated.
   // This is for significant tracking updates, not every frame
   public var trackingUpdated: ((trackingUpdate)->())? = nil
   
   // Required callback for this class to get the image with scene intrinsics.
   // Set in call to startTracking()
   private var getSceneIntrinsic: (()->sceneIntrinsic?)? = nil
   
   public init(config: connectConfig) {
      self.config = config
      downloader = httpDownloader(isCacheEnabled: false, timeout: defaults.defaultHttpTimeout)
   }
   
   public func startTracking(sceneIntrinsicCallback: @escaping ()->sceneIntrinsic? ) {
      self.getSceneIntrinsic = sceneIntrinsicCallback
      
      lastTrackingResult = nil
      trackingTimeInterval = 1
      numConsecutiveFails = 0
      isTracking = true
      
      startTrackingTimer()
   }
   public func stopTracking(){
//      registrationService?.cancelRegistrationRequest()
      stopTrackingTimer()
      isTracking = false
      self.isRegistrationInProgress = false
   }
   
   @objc private func doRegistration(){
      guard isRegistrationInProgress == false else {
         return
      }
      
      isRegistrationInProgress = true
      var trackingUpdateResult:trackingUpdate? = nil
      
      if let getSceneIntrinsic = self.getSceneIntrinsic {
         if let sceneIntrinsic = getSceneIntrinsic(), let fopConfig = config.getConfig(forFop: sceneIntrinsic.locationId), let lid = config.decodedData?.lid {
            if sceneIntrinsic.isDeviceReadyWithTracking && sceneIntrinsic.isUserAtLocation {
               
               self.trackingTimeInterval = Int(fopConfig.registrationDelay ?? defaults.registrationDelay)
               
               DispatchQueue.global(qos: .default).async {
                  platformApis.callConnectApi( downloader: self.downloader,
                     entrypoint: fopConfig.apiEntrypointUrl!,
                     lid: lid,
                     gid: self.config.decodedData?.gid,
                     fop: fopConfig.id,
                     intrinsicData: sceneIntrinsic,
                     completion: self.registrationCallback )
               }
               
               // Make sure we return from here
               return
               
            } else if !sceneIntrinsic.isUserAtLocation {
               self.trackingTimeInterval = Int(fopConfig.shortSecs ?? defaults.shortSecs)
               let timeStamp = UInt64(Date().timeIntervalSince1970)
               trackingUpdateResult = trackingUpdate(error: ERROR.LOCATION,
                  errorMsg: "User is not at location",
                  url: "",
                  sceneIntrinsic: sceneIntrinsic,
                  timestamp: timeStamp )
            } else {
               self.trackingTimeInterval = Int(fopConfig.shortSecs ?? defaults.shortSecs)
               let timeStamp = UInt64(Date().timeIntervalSince1970)
               trackingUpdateResult = trackingUpdate(error: ERROR.TRACKING_DEVICE_NOT_READY,
                  errorMsg: "Device tracking condition not met",
                  url: "",
                  sceneIntrinsic: sceneIntrinsic,
                  timestamp: timeStamp )
            }
         } else {
            trackingTimeInterval = 2
            let timeStamp = UInt64(Date().timeIntervalSince1970)
            trackingUpdateResult = trackingUpdate(error: ERROR.INVALID_PARAM,
               errorMsg: "Failed to get scene instrinsic",
               url: "",
               sceneIntrinsic: nil,
               timestamp: timeStamp)
         }
      } else {
         let timeStamp = UInt64(Date().timeIntervalSince1970)
         trackingUpdateResult = trackingUpdate(error: ERROR.INVALID_PARAM,
            errorMsg: "getSceneIntrinsic callback not provided",
            url: "",
            sceneIntrinsic: nil,
            timestamp: timeStamp)
      }
      
      if let callback = self.trackingUpdated, let result = trackingUpdateResult {
         // We only get here if something fails
         callback(result)
         
         // TODO: handle reset here as well? IDK, doesn't seem like this is the intent behind the reset
      }
      
      self.isRegistrationInProgress = false
      
      // Start the tracking if not stopped
      if self.trackingTimer != nil{
         self.startTrackingTimer()
      }
   }
   private func registrationCallback(trackingStatus: trackingUpdate) {
      guard let fopConfig = self.config.getConfig(forFop: trackingStatus.sceneIntrinsic?.locationId) else { return }
      
      switch trackingStatus.error {
         case .NONE:
            // If new confidence value is greater than configured confidence index, then use the new tracking result
            if fopConfig.confidenceIndex ?? defaults.confidenceIndex < trackingStatus.confidenceValue {
               self.lastTrackingResult = trackingStatus
            } else {
               // Check whether there is a previous tacking result
               if let lastTrackingResult = self.lastTrackingResult {
                  let timeDurationSecs = (trackingStatus.timestamp - lastTrackingResult.timestamp)/1000
                  let confidenceDegradePercentage = fopConfig.confidenceDegradePercentage ?? defaults.confidenceDegradePercentage
                  let lastDegradedConfidenceValue = lastTrackingResult.confidenceValue*(pow(confidenceDegradePercentage, (Double(timeDurationSecs)/10)))
                  // Check whether the degraded last confidence value is greater than new tracking result
                  // If YES, not need to use the new tracking result
                  // If NO, use the new tracking result
                  if lastDegradedConfidenceValue > trackingStatus.confidenceValue {
                     self.lastTrackingResult?.confidenceValue = lastDegradedConfidenceValue
                     self.lastTrackingResult?.timestamp = UInt64(Date().timeIntervalSince1970)
                  } else {
                     self.lastTrackingResult = trackingStatus
                  }
               } else {
                  // As there is no previous tracking result use the new one
                  self.lastTrackingResult = trackingStatus
               }
            }
            
            // Adjust the next tracking time interval based on the confidence value
            if (self.lastTrackingResult?.confidenceValue ?? 0) > fopConfig.confidenceHighThreshold ?? defaults.confidenceHighThreshold {
               self.trackingTimeInterval = Int(fopConfig.longSecs ?? defaults.longSecs)
            } else if (self.lastTrackingResult?.confidenceValue ?? 0) > fopConfig.confidenceMediumThreshold ?? defaults.confidenceMediumThreshold {
               self.trackingTimeInterval = Int(fopConfig.mediumSecs ?? defaults.mediumSecs)
            } else {
               self.trackingTimeInterval = Int(fopConfig.shortSecs ?? defaults.shortSecs)
            }
            
            // Update our members
            if trackingStatus.viewPosition.count == 3 {
               self.viewPosition = SIMD3<Double>(Double(trackingStatus.viewPosition[0]), Double(trackingStatus.viewPosition[1]), Double(trackingStatus.viewPosition[2]))
            }
            if trackingStatus.viewDirection.count == 3 {
               self.viewDirection = SIMD3<Double>(Double(trackingStatus.viewDirection[0]), Double(trackingStatus.viewDirection[1]), Double(trackingStatus.viewDirection[2]))
            }
            
            // Make the callback
            if let callback = self.trackingUpdated, let lastTrackingResult = self.lastTrackingResult {
               callback(lastTrackingResult)
            }
         case .HTTP:
            // There was an error
            self.trackingTimeInterval = Int(fopConfig.shortSecs ?? defaults.shortSecs)
            if let callback = self.trackingUpdated {
            
         // TODO: WHERE IS newTrackingUpdate actually used?!
               var newTrackingUpdate = trackingStatus
               // In case of error send the confidence value that currently we are on
               if let lastTrackingResult = self.lastTrackingResult {
                  newTrackingUpdate.confidenceValue = lastTrackingResult.confidenceValue
                  newTrackingUpdate.timestamp = lastTrackingResult.timestamp
               }
               callback(trackingStatus)
               
               // If we've failed consecutively multiple times
               self.numConsecutiveFails += 1
               if let maxAttempts = fopConfig.maxAttemptsBeforeReset, self.numConsecutiveFails > maxAttempts {
                  // Reset
                  // TODO: anything more we should do here?
                  self.numConsecutiveFails = 0
                  
                  // Send a reset update
                  let resetUpdate = Q.trackingUpdate(error: ERROR.TRACKING_RESET,
                     errorMsg: "maxAttemptsBeforeReset(\(maxAttempts)) reached",
                     url: "",
                     sceneIntrinsic: nil,
                     timestamp: UInt64(Date().timeIntervalSince1970) )
                  callback(resetUpdate)
               }
            }
         default:
            // There was an error
            self.trackingTimeInterval = Int(fopConfig.shortSecs ?? defaults.shortSecs)
            if let callback = self.trackingUpdated {
            
            // TODO: WHERE IS newTrackingUpdate actually used?!
               var newTrackingUpdate = trackingStatus
               // In case of error send the confidence value that currently we are on
               if let lastTrackingResult = self.lastTrackingResult {
                  newTrackingUpdate.confidenceValue = lastTrackingResult.confidenceValue
                  newTrackingUpdate.timestamp = lastTrackingResult.timestamp
               }
               callback(trackingStatus)
               
               // If we've failed consecutively multiple times
               self.numConsecutiveFails += 1
               if let maxAttempts = fopConfig.maxAttemptsBeforeReset, self.numConsecutiveFails > maxAttempts {
                  // Reset
                  // TODO: anything more we should do here?
                  self.numConsecutiveFails = 0
                  
                  // Send a reset update
                  let resetUpdate = Q.trackingUpdate(error: ERROR.TRACKING_RESET,
                     errorMsg: "maxAttemptsBeforeReset(\(maxAttempts)) reached",
                     url: "",
                     sceneIntrinsic: nil,
                     timestamp: UInt64(Date().timeIntervalSince1970) )
                  callback(resetUpdate)
               }
            }
      }

      self.isRegistrationInProgress = false
      
      // Register again if the tracking is not stopped
      if self.trackingTimer != nil{
         self.startTrackingTimer()
      }
   }
   private func startTrackingTimer(){
      stopTrackingTimer()
      
      DispatchQueue.main.async {
         self.trackingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.trackingTimeInterval), target: self, selector: #selector(self.doRegistration), userInfo: nil, repeats: false)
      }
   }
   private func stopTrackingTimer() {
      if trackingTimer != nil {
         trackingTimer?.invalidate()
         trackingTimer = nil
      }
   }
}
