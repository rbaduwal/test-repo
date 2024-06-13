//import Foundation
//import Q
//
//public class golfPlayerTeeboxAssociatedData{
//
//   let player: golfPlayer
//   var teeBoxPlayerCard: golfTeeBoxPlayerCard?
//   var showTeeboxCard = true
//
//   convenience init(player: golfPlayer){
//      self.init(player: player, playerInfoCard: nil)
//   }
//   init(player: golfPlayer, playerInfoCard: golfTeeBoxPlayerCard?){
//      self.player = player
//      self.teeBoxPlayerCard = playerInfoCard
//   }
//
//   public func removeAllAssociatedElementsFromScene(){
//      removeInfoCard()
//   }
//
//   fileprivate func removeInfoCard(){
//      teeBoxPlayerCard?.removeFromParent()
//      teeBoxPlayerCard = nil
//   }
//}
