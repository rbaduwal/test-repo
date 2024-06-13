import Q

public class golfPlayerGreenAssociatedData{
   
   let player: golfPlayer
   var greenPlayerCard: golfGreenPlayerCard?
   var ballTraces: [ballPath] = []
   var isReplayButtonTapped: Bool = false
   var apexNode: golfApexCard?
   var cancelPreviousAnimation: Bool = true
   
   var isBallTraceAnimating: Bool {
      return ballTraces.filter({$0.isAnimating}).count > 0 ? true : false
   }
   
   convenience init(player: golfPlayer) {
      self.init(player: player,
         playerStatCard: nil,
         ballTrace: nil,
         apexNode: nil)
   }
   
   init(player: golfPlayer,
      playerStatCard: golfGreenPlayerCard?,
      ballTrace: [ballPath]?,
      apexNode: golfApexCard?) {
      self.player = player
      self.greenPlayerCard = playerStatCard
      self.ballTraces = ballTrace ?? []
      self.apexNode = apexNode
   }
   
   func removeAllAssociatedElementsFromScene() {
      isReplayButtonTapped = false
      removeStatCard()
      removeBallTrace()
      removeApexNode()
   }
   func removeStatCard() {
      greenPlayerCard?.removeFromParent()
      greenPlayerCard?.hide() 
      greenPlayerCard = nil
   }
   func removeApexNode() {
      apexNode?.removeFromParent()
      apexNode = nil
   }
   func removeBallTrace() {
      ballTraces.forEach({
         $0.removeFromParent()
         $0.releaseResources()
      })
      ballTraces.removeAll()
   }
   func animateBallTrace() {
      if !ballTraces.isEmpty{
         ballTraces.forEach({$0.prepareToAnimate()})
         self.cancelPreviousAnimation = true
         animate(currentIndex: 0, numberOfBallTraces: ballTraces.count)
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
   private func animate(currentIndex: Int, numberOfBallTraces: Int) {
      ballTraces[currentIndex].startAnimation { [weak self] in
         let nextIndex = currentIndex + 1
         if nextIndex < numberOfBallTraces{
            self?.cancelPreviousAnimation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().delayBetweenShotAnimation ?? defaults.delayBetweenShotAnimation)) {
               if(self?.cancelPreviousAnimation == false) {
                  self?.animate(currentIndex: nextIndex, numberOfBallTraces: numberOfBallTraces)
               }
            }
         } else {
            if let playerID = self?.player.pid {
               NotificationCenter.default.post(name: Notification.Name(constants.ballTraceReplayDidCompleteNotification), object: nil, userInfo: ["playerID": playerID])
            }
         }
      }
   }
}
