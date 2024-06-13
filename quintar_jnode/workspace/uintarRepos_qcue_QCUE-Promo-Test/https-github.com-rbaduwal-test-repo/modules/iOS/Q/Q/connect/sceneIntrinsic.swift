import Foundation

public struct sceneIntrinsic {
   
   public let cameraTransform: [Double]
   public let cameraIntrinsics: [Double]
   public let image: Data
   public let imageWidth: Int
   public let imageHeight: Int
   public var timeStamp: UInt64 = 0
   public var misc: String = ""
   public var deviceType = ""
   public var deviceName = ""
   public var currentExposureBias: Float = 0
   public var locationId: String
   public var isDeviceReadyWithTracking: Bool
   public var isUserAtLocation: Bool
   public let deviceTrackingState: deviceTrackingState
   
   public init( cameraTransform: [Double],
      cameraIntrinsics: [Double],
      image: Data,
      imageWidth: Int,
      imageHeight: Int,
      timeStamp: UInt64,
      misc: String,
      locationId: String,
      isDeviceReadyWithTracking: Bool,
      isUserAtLocation: Bool,
      deviceName: String,
      deviceType: String,
      currentExposureBias: Float,
      deviceTrackingState: deviceTrackingState = Q.deviceTrackingState() ) {

      self.cameraTransform = cameraTransform
      self.cameraIntrinsics = cameraIntrinsics
      self.image = image
      self.imageWidth = imageWidth
      self.imageHeight = imageHeight
      self.timeStamp = timeStamp
      self.misc = misc
      self.locationId = locationId
      self.isDeviceReadyWithTracking = isDeviceReadyWithTracking
      self.isUserAtLocation = isUserAtLocation
      self.deviceType = deviceType
      self.deviceName = deviceName
      self.currentExposureBias = currentExposureBias
      self.deviceTrackingState = deviceTrackingState
   }
   
   public func serialize()->(image: Data, json: Data?) {
      let intrinsic = ["img_width": Int(imageWidth),
         "img_height": Int(imageHeight),
         "cam_extrinsics": cameraTransform,
         "cam_intrinsics": cameraIntrinsics,
         "lat": deviceTrackingState.location.lat,
         "lon": deviceTrackingState.location.lon,
         "altitude": deviceTrackingState.location.altitude,
         "latlonAccuracy": deviceTrackingState.location.latlonAccuracy,
         "altitudeAccuracy": deviceTrackingState.location.altitudeAccuracy,
         "magnetic_field": [deviceTrackingState.heading.heading.x, deviceTrackingState.heading.heading.y, deviceTrackingState.heading.heading.z],
         "gravity": [deviceTrackingState.gravity.x, deviceTrackingState.gravity.y, deviceTrackingState.gravity.z],
         "epochSecs": timeStamp,
         "misc": misc,
         "headingAccuracy": deviceTrackingState.heading.accuracy,
         "deviceName": deviceName,
         "deviceType": deviceType,
         "currentExposureBias": currentExposureBias] as NSDictionary
      
      let json = try? JSONSerialization.data(withJSONObject: intrinsic, options: JSONSerialization.WritingOptions(rawValue: 0))
      return(image, json)
   }
}
