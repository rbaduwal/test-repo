import Foundation

public protocol team: Equatable {

   associatedtype player_t where player_t: player
     
   // Team ID (group number for golf)
   var tid: Int { get }
   
   // Players in this team (or group)
   var players: [player_t] { get }
   
   // Color palette for this team
   var colors: [color] { get set }
   
   // true if this is the home team, false otherwise
   var isHome: Bool { get }
   
   // Name of the team
   var name: String { get }
   
   // Logo URL for the team
   var logoUrl: String { get }
}
