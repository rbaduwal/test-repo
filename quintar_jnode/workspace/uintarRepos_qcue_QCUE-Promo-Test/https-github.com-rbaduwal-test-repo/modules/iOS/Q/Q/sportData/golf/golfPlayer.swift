import propsyncSwift

public class golfPlayer: player {
   
   // player implementation
   public var pid: Int { self.playerProps["id"]?.get() ?? -1 }
   public var fn: String { self.playerProps["fn"]?.get() ?? "" }
   public var sn: String { self.playerProps["sn"]?.get() ?? "" }
   public var jn: Int { -1 } // N/A
   public var hsUrl: String { self.playerProps["hs"]?.get() ?? "" }
   public var ht: String { "" } // ignore
   public var cfUrl: String { self.playerProps["cf"]?.get() ?? "" }
   public var team: golfGroup? = nil
   public var colors: [color] = []
   public var playerUpdated: ((golfPlayer) ->())? = nil
   
   // Golf player stuff
   public var teeTime: String { self.playerProps["teeTime"]?.get() ?? "00:00" }
   public var score: Int? { self.playerProps["score"]?.get() }
   public var position: Int? { self.playerProps["position"]?.get() } // TODO: is this logic sound? Will score an position be unavailable until they have valid values?
   public var teeOrder: Int { self.playerProps["teeOrder"]?.get() ?? -1 }
   public var isTied: Bool { self.playerProps["isTied"]?.get() ?? false }
   public private(set) var withdrawn: Bool = false
   public private(set) var playedHoles: [golfPlayedHole] = []
   public private(set) var playerProps: property
   private let sportData: sportData   
   
   init( sportData: sportData, group: golfGroup, playerProps: property ) {
      self.sportData = sportData
      self.team = group
      self.playerProps = playerProps
      self.playerProps.childAdded = onChildAdded
      self.setColor()
   }
   
   public func setColor() {
      let index = self.team?.players.count ?? 0
      let playerColors = self.team?.sportData.config.decodedData?.playerColors ?? defaults.playerColors
      if !playerColors.isEmpty {
         let colorIndex = index%playerColors.count
         if colorIndex < playerColors.count {
            self.colors.append(color(hexString: playerColors[colorIndex]))
         }
      }
   }
   
   // Equatable implementation
   public static func == (lhs: golfPlayer, rhs: golfPlayer) -> Bool {
      if lhs === rhs {
         return true
      } else {
         return lhs.pid == rhs.pid &&
            lhs.team?.round.num == rhs.team?.round.num
      }
   }
   public static func score2str( _ score: Int? ) -> String {
      var scoreText = "--"
      if let score = score {
         scoreText = (score == 0) ? "E" : ((score > 0) ? "+\(score)" : "\(score)")
      }
      return scoreText
   }
   
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {
         case "score",
            "position",
            "isTied",
            "withdrawn":
               p.valueChanged = { (xpath, p) in
                  self.triggerPlayerUpdated()
               }
         case "holes":
            for h in p {
               if let holeNum: Int = h["num"]?.get(), !self.playedHoles.contains( where: {$0.num == holeNum} ) {
                  let playedHole = golfPlayedHole(sportData: sportData, playerHoleProps: h)
                  playedHole.shotAdded = { newShot in self.triggerPlayerUpdated() }
                  self.playedHoles.append( playedHole )
               }
               self.triggerPlayerUpdated()
            }
         default: break
      }
   }
   private func triggerPlayerUpdated() {      
      // Trigger a callback ONLY if we have a valid pid
      if let callback = playerUpdated, self.pid != -1 {
         callback( self )
      }
      sportData.postNotification(name: constants.playerDidChangeNotification, object: nil, userInfo: ["data": self], canDefer: true)
   }
}
