import Foundation

public protocol player: Equatable {
   
   associatedtype player_t where player_t: player
   associatedtype team_t where team_t: team
   
   // Player ID
   var pid: Int { get }
   
   // First name
   var fn: String { get }
   
   // Last name (second name)
   var sn: String { get }
   
   // Jersey number
   var jn: Int { get }
   
   // Headshot URL
   var hsUrl: String { get }
   
   // Hometown
   var ht: String { get }
   
   // Country flag
   var cfUrl: String { get }
      
   // Team (group for golf)
   var team: team_t? { get }
   
   // Color pallette for this player
   var colors: [color] { get set }
   
   // Event when something is updated   
   var playerUpdated: ((player_t) ->())? { get set }
}
