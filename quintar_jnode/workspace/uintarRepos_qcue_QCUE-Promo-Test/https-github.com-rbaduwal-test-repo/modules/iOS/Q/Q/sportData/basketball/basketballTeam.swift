import Foundation
import propsyncSwift

public class basketballTeam: team {

   // team implementation
   public var tid: Int { self.teamProps["tid"]?.get() ?? -1 }
   public private(set) var players: [basketballPlayer] = []
   public var colors: [color] {
      get {
         var returnValue: [color] = []
         if let cs = self.teamProps["colors"] {
            for c in cs {
               returnValue.append(color(hexString: c.get()) )
            }
         }
         return returnValue
      }
      set { /* Impelement if needed */ }
   }
   public var isHome: Bool { (self.teamProps["isHome"]?.get() ?? 1) == 1 }
   public var name: String { self.teamProps["na"]?.get() ?? "" }
   public var abreviatedName: String { self.teamProps["ab"]?.get() ?? "" }
   public var logoUrl: String { self.teamProps["logo"]?.get() ?? "" }
   
   // basketballTeam stuff
   public private(set) var teamProps: property
   public private(set) var leadersProps: property? = nil
   public var city: String { self.teamProps["ci"]?.get() ?? "" }
   public internal(set) var leaders: [String:basketballTeamLeader] = [:] // 3-letter category, leader
   public private(set) var heatmaps: [basketballHeatmap] = []
   public var leaderUpdated: ((basketballTeam)->())? = nil
   private var config: sportDataConfig
   private let sportData: sportData
   
   init( sportData: sportData, teamProps: property, config: sportDataConfig ) {
      self.sportData = sportData
      self.teamProps = teamProps
      self.config = config
      update(config: config)
   }
   
   // Equatable implementation
   public static func == (lhs: basketballTeam, rhs: basketballTeam) -> Bool {
      if lhs === rhs {
         return true
      } else {
         return lhs.tid == rhs.tid
      }
   }
   public func update( config: sportDataConfig ) {
      self.config = config
      
      if let entrypointUrl = config.decodedData?.apiEntrypointUrl,
         let lid = config.decodedData?.lid {
         
         do {
            // players API
            if let playersData = try platformApis.callPlayersApi(entrypoint: entrypointUrl,
               lid: lid,
               tid: self.tid) {
            
               // Move players to under the teams hierarchy
               if var playersArray = try playersData["players"]?.extract() {
                  try self.teamProps.upsert("players", p: &playersArray, policy: .KEEP_NEW)
               }
            }
         } catch let e {
            log.instance.push(.ERROR, msg: "\(e)")
         }
      }

      if let pa = self.teamProps["players"] {
         for p in pa {
            if let pid: Int = p["pid"]?.get(), let existingPlayer = self.players.first( where: {$0.pid ==  pid} ) {
               existingPlayer.update( withNewPlayerProps: p )
            }
            else if let tid: Int = p["tid"]?.get(), tid == self.tid {
               self.players.append( basketballPlayer( sportData: self.sportData, team: self, playerProps: p ) )
            }
         }
      }
   }
   public func update( withLeadersProps: property ) {
      self.leadersProps = withLeadersProps
      self.leadersProps?.childAdded = { (xpath, p) in
         p.childAdded = { (xpath, child) in
            switch p.key {
               case "AST", "BLK", "PTS", "REB", "STL":
                  self.leaders[p.key] = basketballTeamLeader(sportData: self.sportData, team: self, leaderProps: p)

                  // Unlike other sport data objects, the team more-or-less owns the game leaders as a fixed collection.
                  // Let's monitor the 'scr' value and send notifications from the team, not the leader themself
                  p.childAdded = { (xpath, child) in
                     switch child.key {
                        case "scr":
                           child.valueChanged = { (xpath, p) in self.triggerLeaderUpdated() }
                        default: break
                     }
                  }
               default: break
            }
         }
      }
   }
   private func triggerLeaderUpdated() {
      if let callback = leaderUpdated {
         callback( self )
      }
      self.sportData.postNotification(name: constants.leaderUpdated, object: nil, userInfo: ["data": self], canDefer: true)
   }
}
