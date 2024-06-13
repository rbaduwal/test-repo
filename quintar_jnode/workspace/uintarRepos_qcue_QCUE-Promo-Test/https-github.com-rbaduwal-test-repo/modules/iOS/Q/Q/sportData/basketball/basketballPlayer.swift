import propsyncSwift

public class basketballPlayer: player {
   
   // player implementation
   public var pid: Int { self.playerProps["pid"]?.get() ?? -1 }
   public var fn: String { self.playerProps["fn"]?.get() ?? "" }
   public var sn: String { self.playerProps["sn"]?.get() ?? "" }
   public var jn: Int { self.playerProps["jn"]?.get() ?? -1 }
   public var hsUrl: String { self.playerProps["hs"]?.get() ?? "" }
   public var ht: String { self.playerProps["ht"]?.get() ?? "" }
   public var cfUrl: String { "" } // N/A, use team flag
   public private(set) var team: basketballTeam? = nil
   public var colors: [color] = [] // N/A - use team colors
   public var playerUpdated: ((basketballPlayer) ->())? = nil
   
   // basketballPlayer stuff   
   public private(set) var heatmaps: [basketballHeatmap] = []
   public private(set) var shots: [basketballShot] = []
   private var playerProps: property
   private let sportData: sportData
   
   init( sportData: sportData, team: basketballTeam, playerProps: property  ) {
      self.sportData = sportData
      self.team = team
      self.playerProps = playerProps
      update(withNewPlayerProps: playerProps)
   }
   
   public func update( withNewPlayerProps playerProps: property ) {
      self.playerProps = playerProps

      // Trigger a callback ONLY if we have a valid pid
      if let callback = playerUpdated, self.pid != -1 {
         callback( self )
      }
   }
   public func updateShot( withShotProps shotProps: property ) {
      self.sportData.threadSafety.async {
         if let eid = shotProps["eid"], let existingShot = self.shots.first( where: { $0.shotId == eid } ) {
            existingShot.update( withNewShotProps: shotProps )
         } else {
            self.shots.append( basketballShot( sportData: self.sportData, player: self, shotProps: shotProps ) )
         }
      }
   }
   
   // Equatable implementation
   public static func == (lhs: basketballPlayer, rhs: basketballPlayer) -> Bool {
      if lhs === rhs {
         return true
      } else {
         return lhs.pid == rhs.pid
      }
   }
   
   public func shots( ofType shotType: basketballShot.SHOT_TYPE ) -> [basketballShot] {
      self.sportData.threadSafety.sync {
         return shots.filter { $0.type == shotType }
      }
   }
   public func shots( areMade made: Bool ) -> [basketballShot] {
      self.sportData.threadSafety.sync {
         return shots.filter { $0.made == made }
      }
   }
   public func shots( areMade made: Bool , ofType shotType: basketballShot.SHOT_TYPE) -> [basketballShot] {
      self.sportData.threadSafety.sync {
         return shots.filter { $0.made == made && $0.type == shotType }
      }
   }
}
