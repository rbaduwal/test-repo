import CoreMotion
import CoreLocation
import simd

public struct deviceLocation {
   public let lat: Double
   public let lon: Double
   public let latlonAccuracy: Double
   public let altitude: Double
   public let altitudeAccuracy: Double
   
   public init() {
      self.lat = 0
      self.lon = 0
      self.latlonAccuracy = 0
      self.altitude = 0
      self.altitudeAccuracy = 0
   }
   public init( lat: Double,
      lon: Double,
      latlonAccuracy: Double,
      altitude: Double,
      altitudeAccuracy: Double ) {
      
      self.lat = lat
      self.lon = lon
      self.latlonAccuracy = latlonAccuracy
      self.altitude = altitude
      self.altitudeAccuracy = altitudeAccuracy
   }
   public init( _ location: CLLocation ) {
      self.lat = location.coordinate.latitude
      self.lon = location.coordinate.longitude
      self.latlonAccuracy = location.horizontalAccuracy
      self.altitude = location.altitude
      self.altitudeAccuracy = location.verticalAccuracy
   }
}

public struct deviceHeading {
   public let heading: SIMD3<Double>
   public let accuracy: Double
   
   public init() {
      self.heading = [0,0,0]
      self.accuracy = 0
   }
   public init( heading: SIMD3<Double>,
      accuracy: Double ) {
      
      self.heading = heading
      self.accuracy = accuracy
   }
   public init( _ heading: CLHeading ) {
      self.heading = [ heading.x, heading.y, heading.z ]
      self.accuracy = heading.headingAccuracy
   }
}

public struct deviceTrackingState {
   public let location: deviceLocation
   public let heading: deviceHeading
   public let gravity: SIMD3<Double>
   
   public init() {
      self.location = deviceLocation()
      self.heading = deviceHeading()
      self.gravity = [0,0,0]
   }
   public init( location: deviceLocation,
      heading: deviceHeading,
      gravity: SIMD3<Double> ) {
      
      self.location = location
      self.heading = heading
      self.gravity = gravity
   }
   public init( location: CLLocation,
      heading: CLHeading,
      gravity: CMAcceleration ) {
      
      self.location = deviceLocation(location)
      self.heading = deviceHeading(heading)
      self.gravity = [ gravity.x, gravity.y, gravity.z ]
   }
}

public class deviceTracking: NSObject, CLLocationManagerDelegate {
   private var locationManager: CLLocationManager!
   private var motionManager = CMMotionManager()
   private var usingLocation = false
  
   public var currentState: deviceTrackingState? {
      get {
         guard let location = locationManager.location else {return nil}
         guard let heading = locationManager.heading else { return nil }
         guard let deviceMotion = motionManager.deviceMotion else {return nil}

         return deviceTrackingState( location: location,
            heading: heading,
            gravity: deviceMotion.gravity )
      }
   }
   public var gravityCoefficients: SIMD3<Double>? {
       
       guard let motionDevice = motionManager.deviceMotion else {return nil}
       return SIMD3<Double>(motionDevice.gravity.x, motionDevice.gravity.y, motionDevice.gravity.z)
   }
   // TODO: Refactor or remove these. Let the caller determine how to use the data in tracking state
   public var deviceRollAngle: Float {
      if let data = motionManager.accelerometerData {
         let deviceRotation = getRotatedAngle(accelaration: data.acceleration)
         return deviceRotation
      }
      return 45.0
   }
   
   public override init() {
      super.init()
      locationManager = CLLocationManager()
      locationManager.delegate = self
   }
   
   public func start( useLocation: Bool ) {
      self.usingLocation = useLocation
      
      motionManager.startDeviceMotionUpdates()
      motionManager.startAccelerometerUpdates()
      locationManager.startUpdatingHeading()
      
      if self.usingLocation {
         locationManager.requestWhenInUseAuthorization()
         locationManager.startUpdatingLocation()
      }
   }
   public func stop() {
      locationManager.stopUpdatingHeading()
      motionManager.stopDeviceMotionUpdates()
      motionManager.stopAccelerometerUpdates()
      
      if self.usingLocation { locationManager.stopUpdatingLocation() }
   }

   private func getRotatedAngle(accelaration: CMAcceleration) -> Float {
      let rotatedAngleInRadForYaxis = atan2(-accelaration.x, -accelaration.z)
      return Float(rotatedAngleInRadForYaxis * 180 / .pi)
   }
}
