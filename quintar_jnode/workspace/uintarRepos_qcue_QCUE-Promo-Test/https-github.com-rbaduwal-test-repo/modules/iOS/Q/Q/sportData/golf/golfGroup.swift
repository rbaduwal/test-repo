import propsyncSwift

public class golfGroup: team {

   // team implementation
   public var tid: Int { self.groupProps["num"]?.get() ?? -1 }
   public private(set) var players: [golfPlayer] = []
   public var colors: [color] = [] // ignore
   public private(set) var isHome: Bool = false // ignore
   public var name: String { String(self.tid) }
   public private(set) var logoUrl: String = "" // ignore
   
   // Golf group stuff
   public private(set) var round: golfRound
   public enum GROUP_LOCATION: UInt {
      case UPCOMING  = 0x000 // Not at our hole yet
      case IN_QUEUE  = 0x001 // At the teebox but waiting for other group(s). Currently not included in live data, can be ignored for now
      case TEE       = 0x102 // Teeing off. This includes penalty shots
      case APPROACH  = 0x104 // Somewhere after all players have tee'd off, but not all balls on green yet
      case GREEN     = 0x108 // All balls on green
      case DONE      = 0x010 // All balls in cup
      
      public var inPlayOnHole: Bool {
         return (self.rawValue & 0x100) > 0;
      }
   }
   public private(set) var groupProps: property   
   public let sportData: sportData
   
   init( sportData: sportData, round: golfRound, groupProps: property ) {
      self.sportData = sportData
      self.round = round
      self.groupProps = groupProps
      self.groupProps.childAdded = onChildAdded
   }
   
   // Equatable implementation
   public static func == (lhs: golfGroup, rhs: golfGroup) -> Bool {
      if lhs === rhs {
         return true
      } else {
         return lhs.tid == rhs.tid &&
            lhs.round.num == rhs.round.num
      }
   }
   
   /// Current group location at a given hole
   public func location( forHole: golfHole ) -> GROUP_LOCATION {
      var location = GROUP_LOCATION.UPCOMING
      let groupOrder = forHole.roundHoleDetails[round.num - 1].groupOrder
      if let ourIndex = groupOrder.firstIndex(of: self.tid) {
         let liveGroups = forHole.liveGroups
         if liveGroups.count > 0,
            let firstLiveGroup = liveGroups.first,
            let lastLiveGroup = liveGroups.last,
            let firstLiveIndex = groupOrder.firstIndex(of: firstLiveGroup),
            let lastLiveIndex = groupOrder.firstIndex(of: lastLiveGroup) {
              
            if ourIndex > lastLiveIndex {
               location = .UPCOMING
            }
            else if ourIndex >= firstLiveIndex {
               if forHole.groupsOnTee.contains(where: {$0 == self.tid}) {
                  location = .TEE
               }
               else if forHole.groupOnApproach == self.tid {
                  location = .APPROACH
               }
               else {
                  location = .GREEN
               }
            }
            else {
               location = .DONE
            }
         } else if forHole.roundHoleDetails[round.num - 1].completedGroups.contains(self.tid) {
            location = .DONE
         }
      }
      return location
   }
   
   /// Sorted by timestamp
   public func shots( forHole: golfHole ) -> [golfShot]? {
      var playerShots: [golfShot] = []
      for player in self.players {
         if let playedHole = player.playedHoles.first(where: {$0.num == forHole.num}) {
            playerShots.append(contentsOf: playedHole.shots)
         }
      }
      let sortedPlayerShots: [golfShot] = playerShots.sorted{$0.time.toDate.compare($1.time.toDate) == .orderedAscending}
      return sortedPlayerShots
   }
   
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {

         case "players":
            p.childAdded = onPlayerAdded
            
         default: break
      }
   }
   private func onPlayerAdded( xpath: String, playerProps: property ) {
      if let playerId: Int = playerProps["id"]?.get(), !self.players.contains(where: {$0.pid == playerId}) {
         let newPlayer = golfPlayer( sportData: sportData, group: self, playerProps: playerProps )
         self.players.append( newPlayer )
      }
   }
}
