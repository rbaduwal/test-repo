import Foundation

public struct trackingUpdate {
   public let error: ERROR
   public let errorMsg: String
   public let url: String
   public let transform: [Double]
   public let sceneIntrinsic: sceneIntrinsic?
   public let registrationError: registrationError?
   public var timestamp: UInt64
   public var confidenceValue: Double
   public var viewPosition: [Double]
   public var viewDirection: [Double]
   
   public init( error: ERROR,
      errorMsg: String,
      url: String,
      sceneIntrinsic: sceneIntrinsic?,
      timestamp: UInt64,
      transform: [Double] = [],
      confidenceValue: Double = 0,
      viewPosition: [Double] = [0,0,0],
      viewDirection: [Double] = [0,0,0],
      registrationError: registrationError? = nil ) {
      self.error = error
      self.errorMsg = errorMsg
      self.url = url
      self.transform = transform
      self.timestamp = timestamp
      self.confidenceValue = confidenceValue
      self.sceneIntrinsic = sceneIntrinsic
      self.viewPosition = viewPosition
      self.viewDirection = viewDirection
      self.registrationError = registrationError
   }
   public var dictionaryRepresentation: [String: Any] {
      return [
         "error" : self.error,
         "errorMsg" : self.errorMsg,
         "url" : self.url,
         "transform":  self.transform,
         "timestamp":  self.timestamp,
         "confidenceValue": self.confidenceValue,
         "sceneIntrinsic": self.sceneIntrinsic ?? "",
         "viewPosition": self.viewPosition,
         "viewDirection": self.viewDirection
      ]
   }
}
