import propsyncSwift

public class basketballTeamLeader {
   
   public var player: basketballPlayer? {
      if let pid: Int = self.leaderProps["pid"]?.get() {
         return self.team.players.first(where: {$0.pid == pid})
      } else {
         return nil
      }
   }
   public var value: Int { self.leaderProps["scr"]?.get() ?? -1 }
   private let leaderProps: property
   private let team: basketballTeam
   private let sportData: sportData
   
   init( sportData: sportData, team: basketballTeam, leaderProps: property ) {
      self.sportData = sportData
      self.team = team
      self.leaderProps = leaderProps
   }
}
