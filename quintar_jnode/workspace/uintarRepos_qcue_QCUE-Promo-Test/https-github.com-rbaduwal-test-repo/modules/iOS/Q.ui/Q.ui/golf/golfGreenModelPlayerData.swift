import Q

class golfGreenModelPlayerData {
   
   let player: golfPlayer
   var playerInfo: qEntity?
   var ballTraces: [ballPath] = []
   var greenModelPlayerCard: golfGreenModelPlayerCard?
   var cancelPreviousAnimation: Bool = true
   var isReplayButtonTapped: Bool = false
   
   convenience init(player: golfPlayer){
      self.init(player: player, playerInfo: nil)
   }
   
   init(player: golfPlayer, playerInfo: qEntity?){
      self.player = player
      self.playerInfo = playerInfo
   }
   
   func removeAllFromParentNode(){
      playerInfo?.removeFromParent()
      ballTraces.forEach {
         $0.removeFromParent()
         $0.releaseResources()
      }
      ballTraces.removeAll()
      greenModelPlayerCard?.removeFromParent()
   }   
   func animateBallTrace(){
      if !ballTraces.isEmpty{
         ballTraces.forEach({$0.prepareToAnimate()})
         self.cancelPreviousAnimation = true
         animate(currentIndex: 0, numberOfBallTraces: ballTraces.count)
      }
   }
   func prepareToAnimate(){
      if !ballTraces.isEmpty{
         ballTraces.forEach({$0.prepareToAnimate()})
         self.cancelPreviousAnimation = true
      }
   }
   func animateNewBallTrace(newTraces: [ballPath]) {
      // Called when new traces are obtained.
      if !newTraces.isEmpty{
         let existingTraceCount = ballTraces.count
         newTraces.forEach({$0.prepareToAnimate()})
         ballTraces.append(contentsOf: newTraces)
         animate(currentIndex: existingTraceCount, numberOfBallTraces: ballTraces.count)
      }
   }
   private func animate(currentIndex:Int,numberOfBallTraces:Int){
      ballTraces[currentIndex].startAnimation {[weak self] in
         let nextIndex = currentIndex + 1
         if nextIndex < numberOfBallTraces{
            self?.cancelPreviousAnimation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().delayBetweenShotAnimation ?? defaults.delayBetweenShotAnimation)) {
               if(self?.cancelPreviousAnimation == false) {
                  self?.animate(currentIndex: nextIndex, numberOfBallTraces: numberOfBallTraces)
               }
            }
         }
      }
   }
   func hidePlayerCard() {
      self.greenModelPlayerCard?.hide()
   }
   func showPlayerCard() {
      if(!ballTraces.isEmpty) {
         self.greenModelPlayerCard?.show()
      }
   }
}
