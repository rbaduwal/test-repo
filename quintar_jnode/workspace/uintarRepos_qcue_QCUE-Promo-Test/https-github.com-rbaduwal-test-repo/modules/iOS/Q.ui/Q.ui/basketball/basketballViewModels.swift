import Q

public protocol basketballViewModel: AnyObject {

   var sportData: basketballData { get }
   
   var selectedPlayers: [basketballPlayer] { get set }
   var selectedTeam: basketballTeam? { get set }
   var selectedShotType: basketballShot.SHOT_TYPE { get set }
   
   // Array of one-based periods, where values of 1-4 are normal play, 5+ are overtime
   var selectedPeriods: [Int] { get set }   
   
   // Events when value change
   var playersSelected: (([basketballPlayer ])->())? { get set }
   var teamSelected: ((basketballTeam?)->())? { get set }
   var shotTypeSelected: ((basketballShot.SHOT_TYPE)->())? { get set }
   var periodSelected: (([Int])->())? { get set }
}
