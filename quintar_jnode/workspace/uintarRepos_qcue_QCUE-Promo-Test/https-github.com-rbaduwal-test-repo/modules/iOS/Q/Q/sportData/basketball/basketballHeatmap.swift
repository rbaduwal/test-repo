import Foundation
import propsyncSwift

public class basketballHeatmap: Equatable {
   
   // basketballTeam stuff
   public private(set) var tid: Int
   public private(set) var courtIndex: Int
   public private(set) var attempted: Int
   public private(set) var made: Int
   public private(set) var percentage: Double
   
   // JSON parsing from games API
   public struct decodableBasketballHeatMap: Decodable {
      var tid: Int = 0
      var ci: Int = 0
      var at: Int = 0
      var ma: Int = 0
      var pct: Double = 0
   }
   
   init( decodable: decodableBasketballHeatMap ) {
      self.tid = decodable.tid
      self.courtIndex = decodable.ci
      self.attempted = decodable.at
      self.made = decodable.ma
      self.percentage = decodable.pct
   }
   
   // Equatable implementation
   public static func == (lhs: basketballHeatmap, rhs: basketballHeatmap) -> Bool {
      if lhs === rhs {
         return true
      } else {
         return lhs.tid == rhs.tid
      }
   }
   
   // propsync stuff
   internal var property: property? = nil{
      didSet {
         if let property = property {
            attachProperty(property)
         }
      }
   }
   private func attachProperty(_ property: property) {
//      property.childAdded = { (xpath, childProperty) in
//         switch childproperty.key() {
//            case "players":
//               property.childAdded = { (xpath, childProperty) in
//                  if let p = childProperty.Find( "num" ), let pid: Int = p.Get() {
//                     if let i = self.players.firstIndex( where: { existingPlayer in
//                        existingPlayer.pid == pid
//                     }) {
//                        self.players[i].property = childProperty
//                     } else {
//                        log.instance.push(.ERROR, msg: "Could not find player \(pid), group \(self.tid), in games API data - maybe it needs to be updated?")
//                     }
//                  }
//               }
//            default: break //log.instance.push(.INFO, "Unhandled property \(childproperty.key()) ")
//         }
//      }
   }
}
