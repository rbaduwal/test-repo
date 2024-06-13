import propsyncSwift

public class golfShot: Equatable {

   public enum TYPE {
      case TEE
      case PUTT
      case CHIP
      case UNKNOWN
   }
   
   public var apexHeight: Double { self.shotProps["ballApexHeight"]?.get() ?? 0.0 }
   public var apexLocation: Double { self.shotProps["ballApexLocation"]?.get() ?? 0.0 }
   public var speed: Double { self.shotProps["ballSpeed"]?.get() ?? 0.0 }
   public var time: String { self.shotProps["time"]?.get() ?? "" }
   public var shotId: Int { self.shotProps["shotId"]?.get() ?? -1 }
   public var lie: SIMD3<Double>? {
      if let l: [Double] = self.shotProps["lie"]?.get() {
         return utility.array2vec(l)
      }
      return nil
   }
   public var lieTurf: String { self.shotProps["lieTurf"]?.get() ?? "" }
   public var distance: Double { self.shotProps["distance"]?.get() ?? 0.0 }
   public var distanceToPin: Double { self.shotProps["distanceToPin"]?.get() ?? 0.0 }
   public var stroke: Int { self.shotProps["stroke"]?.get() ?? 0 }
   public var penalty: Bool { self.shotProps["isPenalty"]?.get() ?? false }
   public var type: TYPE
   public private(set) var trace: [SIMD3<Double>] = [SIMD3<Double>]()
   public private(set) var shotProps: property
   public var shotUpdated: ((golfShot) ->())? = nil
   private let sportData: sportData
   
   // Equatable implementation
   public static func == (lhs: golfShot, rhs: golfShot) -> Bool {
      if lhs === rhs {
         return true
      } else {
         return lhs.shotId == rhs.shotId
      }
   }
   
   // TODO: shot type should come from the data, not from the constructor!
   init( sportData: sportData, shotType: TYPE, shotProps: property ) {
      self.sportData = sportData
      self.type = shotType
      self.shotProps = shotProps
      self.shotProps.childAdded = onChildAdded
   }
   
   func triggerOnShotUpdated() {
      if let callback = self.shotUpdated {
         callback( self )
      }
   }
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {
         case "distance",
            "ballApexHeight",
            "ballApexLocation",
            "ballSpeed",
            "lie",
            "isPenalty",
            "distanceToPin",
            "score":
            p.valueChanged = { (xpath, property) in
               self.triggerOnShotUpdated()
            }
         case "trace":
            p.valueChanged = onTraceChanged
         default: break
      }
   }
   private func onTraceChanged( xpath: String, p: property ) {
      var traceDoubleArray: [Double]? = nil
      switch ( p.type ) {
         case property.valueType.BYTE_ARRAY:
            if var traceByteArray: [UInt8] = p.get() {
               do {
                  try? traceDoubleArray = Zfp.decode(&traceByteArray, traceByteArray.count)
               }
            }
         default:
            traceDoubleArray = p.get()
      }
      
      if let array = traceDoubleArray {
         self.trace = utility.array2vec(array)
         self.triggerOnShotUpdated()
      }
   }
}
