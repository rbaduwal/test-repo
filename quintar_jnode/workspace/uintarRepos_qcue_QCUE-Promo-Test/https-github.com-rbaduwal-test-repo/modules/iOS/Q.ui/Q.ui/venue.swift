import UIKit
import ARKit
import Q

open class venue: NSObject, sportExperience, ARSessionDelegate {
   // types
   public struct decodedDataTest: Decodable {
      let fops: [fop]?
      struct fop: Decodable {
         let id: String
         let testImageUrl: String?
         let testJsonUrl: String?
         let apiSimEntrypointUrl: String?
         let outlines: [outlineConfig]?
         
         struct outlineConfig: Decodable {
            let outlineUrl: String?
            var color: String? = defaults.outlineColor
            var opacity: Float? = defaults.outlineOpacity
            var radius: Float? = defaults.outlineRadius
         }
      }
   }
   public enum USER_MODE {
      case LIVE_LIVE
      case REPLAY_LIVE
      case REPLAY
   }
   public enum VENUE_TESTS {
      // Show outlines.
      // Config requirements:
      //   "test": {
      //      "fops": [
      //         {
      //            "id": "...",
      //            "outlines": [
      //               {
      //                  "outlineUrl": "...",
      //                  "color": "...",
      //                  "opacity": 1.0,
      //                  "radius": 0.3
      //               }
      //            ]
      //         }
      //      ]
      //   }
      case OUTLINES
      // Send a test image to a real connect URL.
      // Config requirements:
      //   "test": {
      //      "fops": [
      //         {
      //            "id": "...",
      //            "testImageUrl": "...",
      //            "testJsonUrl": "..."
      //         }
      //      ]
      //   }
      case TEST_IMAGE
      // Send an empty request to a simulation connect URL.
      // Config requirements:
      //   "test": {
      //      "fops": [
      //         {
      //            "id": "...",
      //            "apiSimEntrypointUrl": "...",
      //            ]
      //         }
      //      ]
      //   }
      case SIMULATE_LOCATION
      // Show debug information onscreen.
      // Config requirements: none
      case AR_DEBUG_INFO
      case COURT_MODEL
   }
   
   // properties
   public var geofenceCallback: ((String)->(Bool, String)) = { fop in return ( true, "" ) }
   public var requiredOrientation: ORIENTATION = .ANY   { didSet { handleArStateChange() } }
   public var orientationDefinesArState: Bool = false   { didSet { handleArStateChange() } }
   public var parent: UIViewController? = nil           { didSet { handleArStateChange() } }
   public var fop: String? = nil                        { didSet { handleArStateChange() } }
   public let worldRootEntity: qEntity = qEntity()
   public let rootAnchor = qRootEntity(world: qVector3(0, 0.0, 0))
   public internal(set) var userMode: USER_MODE = .LIVE_LIVE
   public private(set) var outlineRootEntity: qEntity = qEntity()
   public private(set) var test: decodedDataTest?
   public private(set) var arAmbientIntensity: Float = 0.0
   public private(set) var isArTrackingStable = true
   public private(set) var steadyAngle: Float = defaults.steadyAngle
   public private(set) var arViewController: arUiViewController
   public private(set) var inAr: Bool = false
   public private(set) var testModes: [VENUE_TESTS] = []
   public private(set) var usingLocation: Bool = true
   public private(set) var orientation: ORIENTATION = ORIENTATION.ANY
   internal var sensor: deviceTracking?
   internal var successfullyRegisteredOnce: Bool = false
   internal var isRegistrationConditionSatisfied: Bool = false
   internal var testSceneIntrinsic: sceneIntrinsic?
   private weak var presentingViewController: UIViewController? = nil
   private var trackingUpdated: trackingUpdate?
   private var correctionMatrix: SCNMatrix4 = SCNMatrix4Identity
   private var trackingSmoothMoveAnimationFrame: Int = 0
   private var trackingSmoothMoveAnimationTimer = Timer()
   private let trackingSmoothMoveAnimationMaxFrame: Int = 30 // TODO: move to constants, don't hardcode stuff here
   private var smoothMoveFromTransform = simd_float4x4(SCNMatrix4Identity)
   private var smoothMoveToTransform = simd_float4x4(SCNMatrix4Identity)
   
   // init/deinit
   required public init(arViewController: arUiViewController) throws {
      self.arViewController = arViewController
      self.sensor = deviceTracking()
      
      super.init()
      
      // Set the current fop to the first one available. We MUST have at least on field-of-play defined or we fail.
      if let fop = self.arViewController.arUiConfig.connectConfig?.decodedData?.fops?.first?.id {
         self.fop = fop
      } else {
         self.fop = "unknown"
         throw errorWithMessage("Could not find any fields-of-play (fop)")
      }
      sensor?.start( useLocation: usingLocation )
   }
   deinit {
      self.onUninit()
   }
   open func onInit() {
      // Listen for orientation changes and manually call the orientation changed function once, in case we're already in landscape
      NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
      onOrientationChanged()
   }
   open func onUninit() {
      // Stop listening for orientation changes
      NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
   }
   
   // public functions
   open class func doesSupportExperience(sport: SPORT, experience: EXPERIENCE) -> Bool {
      return false
   }
   open func onShow(viewController: arUiViewController) {
   }
   open func onHide(viewController: arUiViewController) {
   }
   open func onAppSuspend() {
      arViewController.sportData?.stopLive()
   }
   open func onAppResume() {
      arViewController.sportData?.startLive()
   }
   open func onFrameUpdated() {
      // TODO: consider adding the frame as an argument
   }
   open func onTrackingRequested() -> Void {
   }
   open func onTrackingUpdated( trackingStatus: trackingUpdate ) -> Void {
      // Main thread please, this touches timers and visuals
      DispatchQueue.main.async {
         switch trackingStatus.error {
            case .NONE:
               // Create the outline, if not added
               if ( self.outlineRootEntity.parent == nil ) {
                  self.worldRootEntity.addChild(self.outlineRootEntity)
                  self.createOutlines()
               }
               
               // Smooth Move - Animate from the previous tracking transform to the new tracking transform
               self.smoothMoveFromTransform = self.smoothMoveToTransform
               self.smoothMoveToTransform = simd_float4x4(trackingStatus.transform)
               self.trackingSmoothMoveAnimationTimer.invalidate()
               self.trackingSmoothMoveAnimationFrame = 0
               
               // Start the smooth move animation
               self.trackingSmoothMoveAnimationTimer = Timer.scheduledTimer(timeInterval: 1.0/Double(self.trackingSmoothMoveAnimationMaxFrame), target: self, selector: #selector(self.onTrackingSmoothMoveTick), userInfo: nil, repeats: true)
            case .TRACKING_RESET:
               break
            default: break
         }
      }
   }
   public func createScene() -> qRootEntity {
      self.worldRootEntity.transform = qTransform(matrix: matrix_identity_float4x4)
      self.rootAnchor.addChild(self.worldRootEntity)
      return self.rootAnchor
   }
   public func destroyScene() {
      self.worldRootEntity.removeFromParent()
   }
   public func enterAr( callbackWhenDone: @escaping (arUiViewUpdate) -> () ) {
      
      // Check the geofence here for the general case, not specific to a FOP yet.
      // We will check FOP-level geofencing later if necessary
      let ( geoFenceOkay, errorMessage ) = self.geofenceCallback("")
      if !geoFenceOkay {
         let returnValue = arUiViewUpdate( error: .LOCATION, errorMsg: errorMessage )
         callbackWhenDone( returnValue )
         return
      }
      
      // Don't continue if we are already in AR
      guard self.inAr == false else {
         let returnValue = arUiViewUpdate( error: .NONE, errorMsg: defaults.alreadyInARMode )
         callbackWhenDone( returnValue )
         return
      }
      
      // Ensure we are in the correct orientation
      guard !orientationDefinesArState || self.requiredOrientation == self.orientation else {
         let returnValue = arUiViewUpdate( error: .INIT, errorMsg: "\(defaults.deviceOrientationIncorrect) \(self.requiredOrientation)" )
         callbackWhenDone( returnValue )
         return
      }
      
      // Ensure we have a parent controller
      guard self.parent != nil else {
         let returnValue = arUiViewUpdate( error: .INIT, errorMsg: defaults.parentNotSet )
         callbackWhenDone( returnValue )
         return
      }
      
      // Mark as in AR before we complete, to avoid ping-pong effect.
      // We'll reset to false below if something fails
      self.inAr = true

      // Let the dispatcher decide when the best time is to do this
      DispatchQueue.main.async {
      
         if let parent = self.parent, self.presentingViewController == nil {

            // Let's go!
            self.presentingViewController = parent
            parent.present( self.arViewController, animated: false, completion: nil )
         }
            
         let returnValue = arUiViewUpdate( error: .NONE, errorMsg: "" )
         callbackWhenDone( returnValue )
      }
   }
   public func leaveAr() {
      if inAr, let parent = self.presentingViewController {
         self.inAr = false
         parent.dismiss( animated: false, completion: nil )
         self.presentingViewController = nil
      }
   }
   public func session( _ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer ) {
   }
   public func session( _ session: ARSession, didUpdate frame: ARFrame ) {
      self.arAmbientIntensity = Float(frame.lightEstimate?.ambientIntensity ?? 0)
      switch frame.camera.trackingState {
      case .notAvailable, .limited(.excessiveMotion), .limited(.insufficientFeatures), .limited(.initializing), .limited(.relocalizing), .limited(_):
          isArTrackingStable = false
      case .normal:
          isArTrackingStable = true
      }
      
      self.onFrameUpdated()
      arViewController.onDrawBegin?()
   }
   public func startTracking( useLocationServices: Bool ) {
      usingLocation = useLocationServices
      
      // Check whether tracking is already started, if not start tracking
      guard let tracker = self.arViewController.tracker else { return }
      if !tracker.isTracking {
         
         // Reset the smooth move animation transform
         smoothMoveFromTransform = simd_float4x4(SCNMatrix4Identity)
         smoothMoveToTransform = simd_float4x4(SCNMatrix4Identity)
         
         // If we need to use a test image instead of an image from the camera
         var useTestInfoForRegistration = false
//         var useSimulationUrlForRegistration = false
         if self.testModes.contains(.TEST_IMAGE) {
            // Test mode affects registration ONLY if:
            //  1. a matching fop exists in the test section
            //  2. the fop has a valid image and json that can be downloaded
            if let fops = self.test?.fops, let currentFop = fops.first(where: {$0.id == self.fop}) {
               if currentFop.testImageUrl != nil && currentFop.testJsonUrl != nil {
                  // Call this here to cache the test intrinsic (image + JSON).
                  // This ensures we aren't blocking during callbacks from the main thread,
                  // since the scene intrinsic callback is always called on the main thread
                  // TODO: need a way to know when this is complete!
                  _ = getSceneIntrinsicsTest()
                  useTestInfoForRegistration = true
               }
            }
         }
         // If simulatelocation is enabled
         else if self.testModes.contains(.SIMULATE_LOCATION) {
            // Simulation registration server is only called if:
            //  1. a matching fop exists in the test section
            //  2. the fop has a valid image and json that can be downloaded
            if let fops = self.test?.fops, let currentFop = fops.first(where: {$0.id == self.fop}) {
               if currentFop.apiSimEntrypointUrl != nil {
//                  useSimulationUrlForRegistration = true
                  // TODO: Actually use this value
               }
            }
         }
         
         // Set our callbacks
         tracker.trackingRequested = {
            self.onTrackingRequested()
         }
         tracker.trackingUpdated = { (trackingStatus) -> () in
            if(tracker.isTracking) {
               self.onTrackingUpdated(trackingStatus: trackingStatus)
            }
         }
         
         tracker.startTracking( sceneIntrinsicCallback: {
            
            // If test mode is enabled and we have a test image for the current fop, then use our fake scene intrinsic.
            // Else use the real scene intrinsics as usual
            var sceneIntrinsic:sceneIntrinsic? = nil
            if useTestInfoForRegistration {
               sceneIntrinsic = self.getSceneIntrinsicsTest()
            } else {
               sceneIntrinsic = self.getSceneIntrinsics()
            }
            if let scnIntrinsic = sceneIntrinsic {
               let deviceInfo = self.isDeviceReadyForTracking( deviceTrackingState: scnIntrinsic.deviceTrackingState )
               let ( isUserAtLocation, _ ) = self.geofenceCallback(self.fop!)
               sceneIntrinsic?.isUserAtLocation = isUserAtLocation
               sceneIntrinsic?.isDeviceReadyWithTracking = deviceInfo.ready
            }
            return sceneIntrinsic
            
         } )
      }
   }
   public func stopTracking() {
      guard let tracker = self.arViewController.tracker else { return }
      if tracker.isTracking {
         tracker.stopTracking()
      
         // Stop the smooth move animation
         self.trackingSmoothMoveAnimationTimer.invalidate()
         self.trackingSmoothMoveAnimationFrame = 0
         self.successfullyRegisteredOnce = false
      }
      
      // Hide all AR elements
      self.rootAnchor.isEnabled = false
   }
   public func isDeviceReadyForTracking( deviceTrackingState: deviceTrackingState ) -> (ready: Bool, lightEstimate: Float, deviceOrientationReady: Bool, arStable: Bool) {
      return (ready: true, lightEstimate: 1000, deviceOrientationReady: true, arStable: true)
   }
   public func enableTestModes(_ options: [VENUE_TESTS]) {
      var reinitiateTracking = false
      
      if (options.contains(VENUE_TESTS.TEST_IMAGE) && !testModes.contains(VENUE_TESTS.TEST_IMAGE)) || (!options.contains(VENUE_TESTS.TEST_IMAGE) && testModes.contains(VENUE_TESTS.TEST_IMAGE)) {
         if let tracker = self.arViewController.tracker, tracker.isTracking {
           reinitiateTracking = true
         }
      }
      testModes = options
      
      // Reload or unload our test data
      if testModes.count > 0 {
         do {
            let jsonData = try JSONSerialization.data(withJSONObject: self.arViewController.arUiConfig.testData, options: .prettyPrinted)
            test = try JSONDecoder().decode(decodedDataTest.self, from: jsonData)
         } catch { log.instance.push(.ERROR, msg: "Failed to parse venue test section") }
      }
      else {
         test = nil
      }
      
      // Enable/disable stuff
      self.outlineRootEntity.isEnabled = testModes.contains(.OUTLINES)
      self.arViewController.showArDebugInfo(show: testModes.contains(.AR_DEBUG_INFO))
      
      if reinitiateTracking {
         stopTracking()
      }
   }
   public func onFopChanged(_ fop: String) {
      // Override as needed to handle dynamic FOP switching
   }
   
   // internal functions
   internal func onTrackingSmoothMoveProgress(transform: qTransform) ->Void {
   }
   internal func onTrackingSmoothMoveCompleted(transform: qTransform) ->Void {
      self.successfullyRegisteredOnce = true
   }

   // private functions
   private func createOutlines() {
      DispatchQueue.global(qos: .background).async {
         
         var outlineEnabled = false
         var currentFop: decodedDataTest.fop? = nil
         if self.testModes.contains(.OUTLINES) {
            // Outlines are only available if:
            //  1. test mode is enabled with .OUTLINES
            //  2. a matching fop exists in the test section
            //  3. the fop has a valid outlineUrls array with at least one value
            if let fops = self.test?.fops {
               if let cf = fops.first( where: { $0.id == self.fop }) {
                  currentFop = cf
                  if cf.outlines != nil && cf.outlines!.count > 0 {
                     outlineEnabled = true
                  }
               }
            }
         }
         
         if outlineEnabled,
            let downloader = self.arViewController.arUiConfig.downloader,
            let outlines = currentFop?.outlines {

            for outline in outlines {
               if let outlineUrl = outline.outlineUrl {
                  do {
                     let download = downloader.getJson(outlineUrl)
                     let decodedData: path.pathDecodable = try parseJson(data: download.data)
                     
                     let outlineColor = UIColor( hexString: (outline.color ?? defaults.outlineColor),
                        alpha: CGFloat(outline.opacity ?? defaults.outlineOpacity))
                     let outlineRadius = outline.radius ?? defaults.outlineRadius
                     
                     for segment in decodedData.Segments {
                        DispatchQueue.main.async {
                           let outline = path(
                              with: segment.map {SIMD3<Float>(x: $0.X, y: $0.Y, z: $0.Z)},
                              radius: outlineRadius,
                              edges: 12,
                              maxTurning: 12,
                              material: qUnlitMaterial(color: outlineColor)
                           )
                           
                           self.outlineRootEntity.isEnabled = self.testModes.contains(.OUTLINES)
                           self.outlineRootEntity.addChild(outline)
                        }
                     }
                  } catch let e as errorWithMessage{
                     log.instance.push(.INFO, msg: "Failed to parse the outline data: \(e.localizedDescription)")
                  } catch let e {
                     log.instance.push(.INFO, msg: "Failed to parse the outline data: \(e)")
                  }
               }
            }
         }
      }
   }
   private func setTrackingMatrix(transform: float4x4) {
      ObjectFactory.shared.trackingMatrix = transform
      if !rootAnchor.isEnabled {
         self.rootAnchor.isEnabled = true
      }
      self.correctionMatrix = SCNMatrix4(transform)
      self.worldRootEntity.transform = qTransform(matrix: transform)
   }
   private func getExposureTargetBias() -> Float {
      let device = AVCaptureDevice.default(for: .video)
      return device?.exposureTargetBias ?? 0
   }
   private func getSceneIntrinsics() -> sceneIntrinsic? {
      guard
         let cameraData = getArCameraInfo(),
         let deviceTrackingState = self.sensor?.currentState
      else{
         log.instance.push(.ERROR, msg: "Failed to create scene intrinsic data")
         return nil
      }
      
      var updatedCapturedImage = CIImage(data: cameraData.capturedImageData)
      var updatedCameraData = cameraData
      var compressionQuality = 1.0
      
      if let tracker = arViewController.tracker, let trackerConfig = tracker.config.getConfig(forFop: self.fop) {
         
         let jpegScale = trackerConfig.jpegScale ?? Q.defaults.jpegScale
         // Update camere intrinsics based on the configured scale
         updatedCameraData.intrinsics[0] =   updatedCameraData.intrinsics[0] * jpegScale
         updatedCameraData.intrinsics[4] =   updatedCameraData.intrinsics[4] * jpegScale
         updatedCameraData.intrinsics[6] =   updatedCameraData.intrinsics[6] * jpegScale
         updatedCameraData.intrinsics[7] =   updatedCameraData.intrinsics[7] * jpegScale
         updatedCapturedImage =  updatedCapturedImage?.scale(scaleFactor: jpegScale)
         
         // Convert to Grey scale if congigured
         if tracker.config.getConfig(forFop: self.fop)?.fourcc == "Y800" {
            updatedCapturedImage = updatedCapturedImage?.grayScale()
         }
         
         // Get the configured compression quality
         compressionQuality = Double(trackerConfig.jpegCompression ?? Q.defaults.jpegCompression)
      }
      
      // Location data can be nil
      //let locationData = deviceTrackingState.location
      //let headingAccuracyData = self.sensor?.headingAccuracy ?? 0.0

      //let compassData = [compassValues.compass_x,compassValues.compass_y,compassValues.compass_z]
      //let gravityData = [gravity.gravity_x, gravity.gravity_y,gravity.gravity_z]
      let timeStamp = UInt64(Date().timeIntervalSince1970)
      
      if let image = updatedCapturedImage, let imageData = image.compress(compressionQuality: Float(compressionQuality)) {
         let sceneIntrinsic = sceneIntrinsic(
            cameraTransform: updatedCameraData.transform.map({Double($0)}),
            cameraIntrinsics: updatedCameraData.intrinsics.map({Double($0)}),
            image: imageData,
            imageWidth: Int(image.extent.width),
            imageHeight: Int(image.extent.height),
            timeStamp: timeStamp,
            misc: "Quintar APP",
            locationId: self.fop ?? "",
            isDeviceReadyWithTracking: true,
            isUserAtLocation: true,
            deviceName: ObjectFactory.shared.deviceName,
            deviceType: defaults.deviceTypeiOS, currentExposureBias: getExposureTargetBias(),
            deviceTrackingState: deviceTrackingState )
         
         return sceneIntrinsic
      } else {
         log.instance.push(.INFO, msg: "Failed to capture image for tracking")
         return nil
      }
   }
   private func getSceneIntrinsicsTest() -> sceneIntrinsic? {
      guard self.testSceneIntrinsic == nil else { return self.testSceneIntrinsic }
      
      if let downloader = self.arViewController.arUiConfig.downloader, let fops = self.test?.fops, let cf = fops.first( where: { $0.id == self.fop }), let testJsonUrl = cf.testJsonUrl {
         if let imageUrl = cf.testImageUrl {
            // Download the test image
            downloader.getImageAsync(imageUrl, completion: { imgResult in
               switch imgResult.error {
                  case .NONE:
                     // Download the test json
                     let downloaderResultJson = downloader.getJson(testJsonUrl)
                     switch downloaderResultJson.error {
                        case .NONE:
                           let testJson = downloaderResultJson.data
                           guard let cameraIntrinsics = (testJson["cam_intrinsics"] as? [Double]) else {log.instance.push(.ERROR, msg: constants.testSceneIntrinsicsErrorMessage("cam_intrinsics")); return}
                           guard let gravity = (testJson["gravity"] as? [Double]) else {log.instance.push(.ERROR, msg: constants.testSceneIntrinsicsErrorMessage("gravity")); return}
                           guard let misc = (testJson["misc"] as? String) else {log.instance.push(.ERROR, msg: constants.testSceneIntrinsicsErrorMessage("misc")); return}
                           guard let epoch = testJson["epochSecs"] as? UInt64 else {log.instance.push(.ERROR, msg: constants.testSceneIntrinsicsErrorMessage("epochSecs")); return}
                           
                           if let testImage = imgResult.data, let image = CIImage(image: testImage) {
                              var updatedCameraIntrinsics = cameraIntrinsics
                              var updatedCapturedImage = image
                              var compressionQuality = 1.0
                              
                              // Use identity matrix for camera transform, to get the exact view from the test image
                              let identityMatrix:[Double] = [1.0, 0.0, 0.0, 0.0,
                                                             0.0, 1.0, 0.0, 0.0,
                                                             0.0, 0.0, 1.0, 0.0,
                                                             0.0, 0.0, 0.0, 1.0]
                              
                              // Updated the details with the configured settings
                              if let tracker = self.arViewController.tracker, let fopConfig = tracker.config.getConfig(forFop: self.fop) {
                                 let jpegScale = fopConfig.jpegScale ?? Q.defaults.jpegScale
                                 updatedCameraIntrinsics[0] = updatedCameraIntrinsics[0] * Double(jpegScale)
                                 updatedCameraIntrinsics[4] = updatedCameraIntrinsics[4] * Double(jpegScale)
                                 updatedCameraIntrinsics[6] = updatedCameraIntrinsics[6] * Double(jpegScale)
                                 updatedCameraIntrinsics[7] = updatedCameraIntrinsics[7] * Double(jpegScale)
                                 updatedCapturedImage =  updatedCapturedImage.scale(scaleFactor: jpegScale)
                                 
                                 if tracker.config.getConfig(forFop: self.fop)?.fourcc == "Y800" {
                                    updatedCapturedImage = updatedCapturedImage.grayScale()
                                 }
                                 
                                 compressionQuality = Double(fopConfig.jpegCompression ?? Q.defaults.jpegCompression)
                              }
                              
                              if let imageData = updatedCapturedImage.compress(compressionQuality: Float(compressionQuality)) {
                              
                                 let simulatedTrackingState = deviceTrackingState(
                                    location: deviceLocation( lat: testJson["lat"] as? Double ?? 0.0,
                                       lon: testJson["lon"] as? Double ?? 0.0,
                                       latlonAccuracy: testJson["latlonAccuracy"] as? Double ?? 0.0,
                                       altitude: testJson["altitude"] as? Double ?? 0.0,
                                       altitudeAccuracy: testJson["altitudeAccuracy"] as? Double ?? 0.0 ),
                                    heading: deviceHeading( heading: SIMD3<Double>(testJson["magnetic_field"] as? [Double] ?? [0,0,0]),
                                       accuracy: testJson["headingAccuracy"] as? Double ?? 0.0 ),
                                    gravity: SIMD3<Double>(gravity) )
                                    
                                 let intrensicData = sceneIntrinsic( cameraTransform: identityMatrix,
                                    cameraIntrinsics:updatedCameraIntrinsics,
                                    image: imageData,
                                    imageWidth: Int(updatedCapturedImage.extent.width),
                                    imageHeight: Int(updatedCapturedImage.extent.height),
                                    timeStamp: epoch,
                                    misc: misc,
                                    locationId: self.fop ?? "",
                                    isDeviceReadyWithTracking: true,
                                    isUserAtLocation: true,
                                    deviceName: ObjectFactory.shared.deviceName,
                                    deviceType: defaults.deviceTypeiOS, currentExposureBias: self.getExposureTargetBias(),
                                    deviceTrackingState: simulatedTrackingState )
                                 self.testSceneIntrinsic = intrensicData
                              }
                           }
                        default: log.instance.push(.ERROR, msg: downloaderResultJson.message)
                     }
                  default: log.instance.push(.ERROR, msg: "Could not download test scene intrinsic for connect")
               }
            })
         }
      }
      
      return self.testSceneIntrinsic
   }
   private func getArCameraInfo() -> (transform:[Float],intrinsics:[Float], capturedImageData: Data)?{
      guard let cameraFrame = arViewController.arView.session.currentFrame else {
         return nil
      }
      
      let capturedImage = CIImage(cvPixelBuffer: cameraFrame.capturedImage)
      let capturedImageData = capturedImage.compress(compressionQuality: 1.0)
      
      // In column major order
      var transformData:[Float] = Array(repeating: Float(0), count: 16 )
      var index = 0
      for col in 0...3{
         for row in 0...3{
            transformData[index] = cameraFrame.camera.transform[col,row]
            index += 1
         }
      }
      
      // In column major order
      var intrinsicData:[Float] = Array(repeating: Float(0), count: 9 )
      index = 0
      for col in 0...2{
         for row in 0...2{
            intrinsicData[index] = cameraFrame.camera.intrinsics[col,row]
            index += 1
         }
      }
      return (transformData,intrinsicData,capturedImageData!)
   }
   private func handleArStateChange() {
      // Only apply this logic if we are in charge of entering/leaving AR
      if self.orientationDefinesArState {
         DispatchQueue.main.async {
            //Enter AR view only when alert is dismissed.
            if !self.inAr &&
               self.requiredOrientation == self.orientation &&
                  self.parent != nil && (self.parent?.presentedViewController == nil) {
               
               self.enterAr() { noCallback in }
               
            } else if self.requiredOrientation != self.orientation ||
               self.parent == nil {
               
               self.leaveAr()
            }
         }
      }
   }
   @objc private func onTrackingSmoothMoveTick() {
      self.trackingSmoothMoveAnimationFrame += 1
      
      let timeOfFrame = Double(self.trackingSmoothMoveAnimationFrame)/Double(self.trackingSmoothMoveAnimationMaxFrame)
      let multipliedFrom = simd_mul(Float(1-timeOfFrame), self.smoothMoveFromTransform)
      let multipliedTo = simd_mul(Float(timeOfFrame), self.smoothMoveToTransform)
      let frameTransform = simd_add(multipliedFrom, multipliedTo)
      
      self.setTrackingMatrix(transform: frameTransform)
      self.onTrackingSmoothMoveProgress(transform: qTransform(matrix: frameTransform))
      
      if self.trackingSmoothMoveAnimationFrame >= self.trackingSmoothMoveAnimationMaxFrame {
         self.trackingSmoothMoveAnimationTimer.invalidate()
         self.trackingSmoothMoveAnimationFrame = 0
         self.onTrackingSmoothMoveCompleted(transform: qTransform(matrix: self.smoothMoveToTransform))
      }
   }
   @objc private func onOrientationChanged() {
      if UIDevice.current.orientation.isValidInterfaceOrientation {
         let orientation = UIDevice.current.orientation
         self.orientation = ( orientation == .landscapeLeft) ? .LANDSCAPE : .PORTRAIT
      } else {
         // Determine device orientation using the screen size
         let size = UIScreen.main.bounds.size
         self.orientation = (size.width > size.height) ? .LANDSCAPE : .PORTRAIT
      }
      
      if self.orientationDefinesArState {
         self.handleArStateChange()
      }
   }
}
