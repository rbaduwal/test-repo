import UIKit
import Q

public struct playerViewModel<player_t> where player_t: Q.player
{
   let player: player_t
   let primaryColor: UIColor
   
   // Computed properties
   var playerId: Int { get { return player.pid } }
   var playerImage: String { get { return player.hsUrl } }
   var name: String { get { return player.nameLastCommaFirstInitial } }
   var countryFlag: String { get { return player.cfUrl } }
}

class ballPathViewModel
{
   let shotId: Int
   var waypoints: [SIMD3<Float>] = []
   var radius: Float = defaults.shotRadius
   var color: UIColor = UIColor(hexString: defaults.shotColor)
   var opacity: Float = defaults.shotOpacity
   var numEdges: Int = defaults.shotNumEdges
   var maxNumTurns: Int = 12 // TODO: What exactly is this, and should it be configurable?
   var fadeInPercentage: Float = defaults.shotFadeInPercentage
   var fadeOutPercentage: Float = defaults.shotFadeOutPercentage
   var animationSpeed : Float = defaults.flightAnimationSpeed
   
  // Events when value change
   var waypointsChanged: (([SIMD3<Float>])->())? = nil
   var radiusChanged: ((Float?)->())? = nil
   var colorChanged: ((UIColor)->())? = nil
   var opacityChanged: (([Float])->())? = nil
   
   // Convenience functions
   func point(atIndex: Int) -> SIMD3<Float>? { if atIndex < self.waypoints.count { return self.waypoints[atIndex] }; return nil }
   
   // init
   init( shotId: Int ) { self.shotId = shotId }
}
