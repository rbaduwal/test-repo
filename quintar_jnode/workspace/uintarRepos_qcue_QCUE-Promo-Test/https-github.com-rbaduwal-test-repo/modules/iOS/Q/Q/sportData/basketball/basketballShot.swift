import simd
import propsyncSwift

public class basketballShot {

   public var shotId: Int { self.shotProps["eid"]?.get() ?? -1 }
   public var period: Int { self.shotProps["pe"]?.get() ?? 1 }
   public var tr: String { self.shotProps["tr"]?.get() ?? "00:00" }
   public var made: Bool { (self.shotProps["ma"]?.get() ?? 0) == 1 }
   public var type: SHOT_TYPE {
      guard let shotType: String = self.shotProps["st"]?.get() else { return .UNKNOWN }
      switch shotType {
         case "3pt": return .THREE_PTR
         case "fg": return .FIELD_GOAL
         case "TOT": return .TOTAL
         default: return .UNKNOWN
      }
   }
   public var origin: SIMD2<Float> { SIMD2<Float>(self.shotProps["x"]?.get() ?? 0.0, self.shotProps["y"]?.get() ?? 0.0) }
   public var trace: [Double] { self.shotProps["trace"]?.get() ?? [] }
   
   // basketballShot stuff
   public private(set) var shotProps: property
   public enum SHOT_TYPE: String {
      case THREE_PTR = "3pt"
      case FIELD_GOAL = "fg"
      case TOTAL = "TOT"
      case PERIOD = "PERIOD"
      case UNKNOWN = "UNKNOWN"
   }
   public let player: basketballPlayer
   public var shotUpdated: ((basketballShot) ->())?
   private let sportData: sportData
   
   init( sportData: sportData, player: basketballPlayer, shotProps: property ) {
      self.sportData = sportData
      self.player = player
      self.shotProps = shotProps
      update(withNewShotProps: shotProps)
   }
   
   public func update( withNewShotProps shotProps: property ) {
      self.shotProps = shotProps
      if let callback = self.shotUpdated {
         callback( self )
      }
   }
}
