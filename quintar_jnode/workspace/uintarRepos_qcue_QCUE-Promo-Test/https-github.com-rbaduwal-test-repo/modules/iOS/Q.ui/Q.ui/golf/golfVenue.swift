import UIKit
import simd
import Q

open class golfVenue: venue, golfViewModel {
   // properties
   public var selectedRound: golfRound? {
      get { return _selectedRound }
      set {
         _selectedRound = newValue
      }
   }
   public var selectedPlayers: [golfPlayerViewModel]? {
      get { return _selectedPlayers }
      set {
         _selectedPlayers = newValue
      }
   }
   public var selectedGroup: golfGroup? {
      get { return _selectedGroup }
      set {
         _selectedGroup = newValue
      }
   }
   /// Course-of-play. Some tournaments have multiple courses
   public private(set) var cop: golfCourse? = nil
   /// The experience section of the arUiViewConfig
   public private(set) var experienceConfig: decodableGolfExperienceConfig.experience?
   public private(set) var sportData: golfData?
   internal var hiddenTracesApexNodes: [golfApexCard] = []
   internal var golfApexCardEntity: golfApexCardBaseEntity? = nil
   internal var apexNodeDict = [golfApexCard: qVector3]()
   private var playerRelatedNodes: [golfPlayerGreenAssociatedData] = []
   private var teeBoxNodes: [golfTeeBoxPlayerCard] = []
   private var oneTimeOperationsAfterRegistrationDone: Bool = false
   private var currentRegistrationAnimationFrame: Int = 0
   private var registrationTransformAnimationTimer = Timer()
   private var liveTeeshotAnimationOngoingPlayers = [Int]()
   private var playedThroughPlayers: [golfPlayer] = []
   private var currentStateOfNonGameElements: NSMutableDictionary = NSMutableDictionary()
   private var debugInfoLastSentTime = UInt64(Date().timeIntervalSince1970)
   private var lastLivePlayer: golfPlayer? = nil
   private var greenModelEntity: golfGreenContainer? = nil
   private var playerCardModels = [playerCardModel]()

   // golfViewModel backing members. We need to capture when a property is set,
   // but if called from an opaque protocol instance swift will NOT call `didset` for properties
   // with automatic storge; thus, we need to have our own backing members here.
   // We'd need these if we used functions instead of properties, so nothing really lost.
   private var _selectedRound: golfRound? = nil
   private var _selectedPlayers: [golfPlayerViewModel]? = nil
   private var _selectedGroup: golfGroup? = nil
   private var animationTimer: Timer? = nil {
      willSet {
         animationTimer?.invalidate()
      }
   }
   private var teeBoxCardAnimationTimer: Timer? = nil {
      willSet {
         teeBoxCardAnimationTimer?.invalidate()
      }
   }
   
   // init/deinit
   required public init(arViewController: arUiViewController) throws {
      try super.init(arViewController: arViewController)
      
      ObjectFactory.shared.sportsVenueController = self
      ObjectFactory.shared.arTextLargeFont = qMeshResource.Font.systemFont(ofSize: 1.2, weight: .bold)
      ObjectFactory.shared.arTextSmallFont = qMeshResource.Font.systemFont(ofSize: 1.5, weight: .bold)
      
      self.arViewController.arView.session.delegate = self
      
      // Keep a convenience variable
      self.sportData = self.arViewController.sportData as? golfData
      
      // Load the experience section of the arUiViewConfig, since we are the class which understands this
      if let a = self.arViewController.arUiConfig.data["arUiView"] as? [String: Any] {
         let temp: decodableGolfExperienceConfig = try parseJson(data: a)
         
         // TODO: pick the first experience for now. We whould be picking the appropriate experience
         experienceConfig = temp.experiences.first
      }
      
//      if let sportDataConfig = self.arViewController.arUiConfig.sportDataConfig, let ec = experienceConfig {
//         let playerColors = getPlayerColorsFromHexValues(playerColorsInHex: ec.experiences.first?.playerColors)
//      }
      
      // Trigger our field-of-play notification handler
      onFopChanged( fop ?? "unknown" )
      
      setTapGesture()
   }
   
   // public functions
   open class override func doesSupportExperience(sport: SPORT, experience: EXPERIENCE) -> Bool {
      return sport == .GOLF && experience == .VENUE
   }
   public override func createScene() -> qRootEntity {
      _ = super.createScene()
      return self.rootAnchor
   }
   public override func onFrameUpdated() {
      // Send a notification if our ability to register has changed
      if let dts = sensor?.currentState {
         let (registrationCondition, _, _, _) = isDeviceReadyForTracking(deviceTrackingState: dts)
         if isRegistrationConditionSatisfied != registrationCondition {
            NotificationCenter.default.post(name: Notification.Name.deviceState, object: nil, userInfo: ["isRegistrationConditionSatisfied":registrationCondition])
            self.isRegistrationConditionSatisfied = registrationCondition
         }
      }
   }
   public override func isDeviceReadyForTracking( deviceTrackingState: deviceTrackingState ) -> (ready: Bool, lightEstimate: Float, deviceOrientationReady: Bool, arStable: Bool) {
      // Ensure the gravity x-component has the largest magnitude. This ensures landscape.
      let gravityFail = fabs(deviceTrackingState.gravity.x) < fabs(deviceTrackingState.gravity.y) ||
         fabs(deviceTrackingState.gravity.x) < fabs(deviceTrackingState.gravity.z)
         
      // Perform some orientation checks
      let (isDeviceOrientationReady, isPointedTowardsSky) = isDeviceOrientationReadyForTracking()
      let lightEstimationThreshold = self.arViewController.arUiConfig.connectConfig?.getConfig(forFop: self.fop)?.lightEstimationThreshold ?? Q.defaults.lightEstimationThreshold
      
      // Fail if:
      //  - device gravity vector isn't pointing where it should
      //  - device orientation is not ready
      //  - the light is too low (ignore if a test image is being used)
      if ( gravityFail ||
         (!isDeviceOrientationReady && !isPointedTowardsSky) ||
           arAmbientIntensity < Float(lightEstimationThreshold))  {
         return (ready: false,
            lightEstimate: arAmbientIntensity,
            deviceOrientationReady: isDeviceOrientationReady,
            arStable: isArTrackingStable)
      }
      
      // Fail if:
      //  - our reported tracking state is unstable
      if !isArTrackingStable {
         return (ready: false,
            lightEstimate: arAmbientIntensity,
            deviceOrientationReady: isDeviceOrientationReady,
            arStable: isArTrackingStable)
      }
      
      // Success if we get here
      return (ready: true,
         lightEstimate: arAmbientIntensity,
         deviceOrientationReady: isDeviceOrientationReady,
         arStable: isArTrackingStable)
   }
   public override func onFopChanged( _ fop: String ) {
      self.stopTracking()
      self.testSceneIntrinsic = nil
      DispatchQueue.main.async {
         self.outlineRootEntity.children.forEach{$0.removeFromParent()}
         self.outlineRootEntity.removeFromParent()
         self.removeReplays()
      }
      
      self.fop = fop
      // Set our course of play when the field of play changes
      if let courses = sportData?.courses {
         if let selectedCourse = courses.first( where: { $0.featuredHoles.contains(where: {$0.fop == fop} ) }) {
            self.cop = selectedCourse
         } else {
            log.instance.push(.ERROR, msg: "No course contains \(fop) as a featured hold")
         }
      } else {
         log.instance.push(.WARNING, msg: "No courses loaded in sport data")
      }
   }
   public override func startTracking( useLocationServices: Bool = true ) {
      super.startTracking( useLocationServices: useLocationServices )
   }
   public override func stopTracking() {
      super.stopTracking()
      self.greenModelEntity?.cancelModelPlacement()
   }
   public func showModel(show: Bool) {
      guard let greenModelEntity = self.greenModelEntity else {return}
      
      if !greenModelEntity.isInAllowedDistanceFromCamera() {
         // If the green model is far away from the user, then to initiate model placement mode remove it from parent
         greenModelEntity.removeFromParent()
      }
      
      if show {
         // If there is no parent for green model, then start in the placement mode
         if greenModelEntity.parent == nil {
            greenModelEntity.startEdit()
         }
         greenModelEntity.show()
      } else {
         greenModelEntity.hide()
      }
   }
   public func cancelModelPlacement() {
      self.greenModelEntity?.cancelModelPlacement()
   }
   public func setPlayerVisibility(visibilityModel: playerVisibilityModel) {
      showTeeboxCard(player: visibilityModel.player, show: visibilityModel.isPlayerFlagVisible)
      showApexCard(player: visibilityModel.player, show: visibilityModel.isApexVisible)
      showBallTrace(player: visibilityModel.player, show: visibilityModel.isShotTrailVisible)
   }
   public func switchToLive() {
      if userMode != .LIVE_LIVE {
         startLiveMode()
      }
      greenModelEntity?.onCurrentPlayerChanged()
   }
   public func switchToReplay() {
      if userMode == .LIVE_LIVE {
         stopLiveMode()
      }
   }
   public func getActivePlayers() -> [golfPlayer]? {
      // Return players in the Live Game or manually selected player or nil if no selection is made and no game is Live
      if userMode == .LIVE_LIVE {
         if let currentRoundNumber = sportData?.currentRound?.num,
         let currentHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ) {
            // TODO: IS this correct logic, getting the first group that is in play for this hole? Depends on what behavior of this function
            // is supposed to be - if we are only returning the active group closest to the green then this logic must change
            guard let liveGame = self.sportData?.rounds[currentRoundNumber - 1].groups.first(where: { $0.value.location(forHole: currentHole).inPlayOnHole }) else { return nil }
            return liveGame.value.players
         }
      } else {
         return playedThroughPlayers
      }
      return nil
   }
   public func addReplayForPlayer(player: golfPlayer) {
      // For live player just animate his existing ball trace
      if userMode == .LIVE_LIVE {
         replayLivePlayer(player: player)
      } else {
         loadPlayerNodes(for: player)
         greenModelEntity?.loadPlayerNode(player: player)
      }
   }
   public func addReplayForGroup(group: golfGroup?) {
      self.removeReplays()
      if let group = group, let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let firstShot = group.shots(forHole: selectedHole)?.first {
      
         if let firstPlayer = group.players.first( where: { player in
            player.playedHoles.first(where: {$0.num == selectedHole.num})?.shots.contains {$0.shotId == firstShot.shotId} ?? false
         }) {
            self.loadPlayerNodes(for: firstPlayer, isGroupReplay: true, shotIndexForGroupReplay: 0)
         }
      }
   }
   public func removeReplayForPlayer(player: golfPlayer){
      if userMode == .LIVE_LIVE {
         hideLivePlayerReplay(player: player)
      } else {
         removeTeeBoxCard(player: player)
         removePlayerRelatedNode(player: player)
         // Reset the height multiplier if a player is removed from replay
         resetPlayerCardsHeightMultiplier()
         greenModelEntity?.removePlayerRelatedNode(player: player)
      }
   }
   public func getTeeBoxPlayer() -> golfPlayer? {
      // Return selected player if any and if the game is live return the player with no shots.
      if userMode != .LIVE_LIVE {
         //TODO:- Change the tee box player
         return playedThroughPlayers.first ?? nil
      }
 // TODO: IMPLEMENNT, change to a property, or get rid of
//      if let currentRoundNum = sportData?.currentRound?.num {
//         guard let currentHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ) else { return nil }
//
//         // TODO: IS this correct logic, getting the first group that is on the hole? I think we want to check groups specifically on the teebox, since
//         // this function is called 'getTeeBoxPlayer()'
//         guard let liveGame = self.sportData?.rounds[currentRoundNum - 1].groups.first(where: { $0.value.location(forHole: currentHole).inPlayOnHole }) else {
//            return nil
//         }
//         return liveGame.value.players.first( where: { player in player.shots(forHole: currentHole.num).isEmpty } )
//      }
      return nil
   }
   public func removePlayerRelatedNode(player: golfPlayer) {
      for (index,item) in playerRelatedNodes.enumerated() {
         if player == item.player {
            if let apexnode = playerRelatedNodes[index].apexNode {
                removeApexCard(apexcard: apexnode)
            }
            playerRelatedNodes[index].removeAllAssociatedElementsFromScene()
            playerRelatedNodes.remove(at: index)
            break
         }
      }
   }
   public func removeReplays() {
      //Remove available player related nodes and invalidates the animation timers.
      self.animationTimer?.invalidate()
      self.animationTimer = nil
      self.teeBoxCardAnimationTimer?.invalidate()
      self.teeBoxCardAnimationTimer = nil
      self.teeBoxNodes.forEach({$0.removeFromParent()})
      self.teeBoxNodes.removeAll()
      self.playerRelatedNodes.forEach({$0.removeAllAssociatedElementsFromScene()})
      self.removeAllApexCards()
      self.removeAllHoleoutCards()
      self.playerRelatedNodes.removeAll()
      self.greenModelEntity?.removeAllPlayerNodes()
      self.liveTeeshotAnimationOngoingPlayers.removeAll()
   }
   public func pauseBallTrace() {
       if let animationTimer = animationTimer, animationTimer.isValid {
           animationTimer.fireDate = .distantFuture
       }
       if let teeBoxCardAnimationTimer = teeBoxCardAnimationTimer, teeBoxCardAnimationTimer.isValid {
           teeBoxCardAnimationTimer.fireDate = .distantFuture
       }
       for playerNode in playerRelatedNodes {
           playerNode.ballTraces.forEach ({
              $0.pauseAnimation()
           })
       }
   }
   public func resumeBallTrace() {
       if let animationTimer = animationTimer, animationTimer.isValid {
           animationTimer.fireDate = .now
       }
       if let teeBoxCardAnimationTimer = teeBoxCardAnimationTimer, teeBoxCardAnimationTimer.isValid {
           teeBoxCardAnimationTimer.fireDate = .now
       }
       
       playerRelatedNodes.forEach({ playerNode in
           playerNode.ballTraces.forEach({
               $0.resumeAnimation()
           })
       })
   }
   
   // internal functions
   internal override func onTrackingSmoothMoveProgress(transform: qTransform) ->Void {
      super.onTrackingSmoothMoveProgress(transform: transform)
      self.updatePlayerRelatedNodesPosition()
      self.updateTeeBoxPlayerCardsPosition()
   }
   internal override func onTrackingSmoothMoveCompleted(transform: qTransform) {
      super.onTrackingSmoothMoveCompleted(transform: transform)
      
      if greenModelEntity == nil {
         loadGreenModel()
      }
      
      if !oneTimeOperationsAfterRegistrationDone {
         oneTimeOperationsAfterRegistrationDone = true
         
         // Listen for notifictions
         self.endObserve()
         self.beginObserve()
         
         // Enter live mode
         self.startLiveMode()
         greenModelEntity?.onCurrentPlayerChanged()
      }
   }
   internal func onBallTraceAnimationProgress(player: golfPlayer, shotID: Int, index: Int, point: SIMD3<Float>) {
      if let startPoint = greenModelEntity?.getStartPointOfTeeTraceInGreenModel(player: player) {
         if simd_equal(startPoint, point) {
            greenModelEntity?.animateBallTrace(player: player)
         }
      }
   }
   internal func getBallTraceConfig() -> ballTraceConfig {
      return experienceConfig?.ballTrace ?? ballTraceConfig()
   }
   internal func setApexCard(apexPiont: qVector3) {
       if let golfApexCardEntity = self.golfApexCardEntity {
           golfApexCardEntity.setApexPosition(apexPosition: apexPiont)
           self.rootAnchor.addChild(golfApexCardEntity)
       }
   }
   internal func changeApexCardPosition() {
      let apexNodes = apexNodeDict.filter{ !hiddenTracesApexNodes.contains($0.key) }
      let maxApexPoint = apexNodes.max { $0.value.z < $1.value.z }
      golfApexCardEntity?.setApexPosition(apexPosition: maxApexPoint?.value ?? qVector3.zero)
   }
   
   // private functions
   @objc private func onPlayerDataUpdated(_ notification: Notification) {
   }
   @objc private func onBallTraceAnimationCompleted(_ notification: Notification) {
      let shotId = notification.userInfo?["shotID"] as? Int ?? 0
      if let player = notification.userInfo?["player"] as? golfPlayer,
         let group = player.team {
         
         if let isGroupReplay = notification.userInfo?["isGroupReplay"] as? Bool,
            isGroupReplay,
            let currentHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
            let groupShots = group.shots(forHole: currentHole),
            let shotIndex = groupShots.firstIndex(where: {$0.shotId == shotId }) {

            // If we have group shots remaining
            if shotIndex + 1 < groupShots.count {
               // Find the next shot for group replay.
               let nextShot = groupShots[shotIndex + 1]
               if let nextPlayer = group.players.first(where: {
                  $0.playedHoles.first(where: {$0.num == currentHole.num})?.shots.contains {
                     $0.shotId == nextShot.shotId
                  } ?? false
                  }),
                  let nextPlayersPlayedHole = nextPlayer.playedHoles.first(where: {$0.num == currentHole.num}) {

                  // Setup the next shot
                  let nextPlayersShotIndex = nextPlayersPlayedHole.shots.firstIndex(of: nextShot)
                  if self.playerRelatedNodes.contains(where: { playerNode in
                      playerNode.player == nextPlayer
                  }) {
                      self.updatePlayerNodes(for: nextPlayer, isGroupReplay: isGroupReplay, shotIndexForGroupReplay: nextPlayersShotIndex)
                  } else {
                      self.loadPlayerNodes(for: nextPlayer, isGroupReplay: isGroupReplay, shotIndexForGroupReplay: nextPlayersShotIndex)
                  }
               }
            } else {
               // Group replay is complete
               NotificationCenter.default.post(name: Notification.Name(constants.groupReplayCompleted), object: nil, userInfo: ["data": group])
            }
         }
         
         // TODO: Not sure what this is doing
         if let arrayIndex = self.liveTeeshotAnimationOngoingPlayers.firstIndex(of: player.pid) {
            liveTeeshotAnimationOngoingPlayers.remove(at: arrayIndex)
         }

         playerRelatedNodes.forEach { playerNode in
            if playerNode.player == player,
               let currentHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
               let playedHole = player.playedHoles.first(where: {$0.num == currentHole.num}),
               let currentShot = playedHole.shots.first(where: {$0.shotId == shotId}) {
               
               let playerCard = playerNode.greenPlayerCard
               
               if playerNode.isReplayButtonTapped || userMode != .LIVE_LIVE {
                  let playerScore = self.getPlayerScoreForReplayBasedOnShot(player: player, currentShot: currentShot)
                  playerCard?.viewModel.totalScore = playerScore
               }
               
               playerCard?.viewModel.shotDistance = Float(currentShot.distance)
               playerCard?.viewModel.shotNumber = currentShot.stroke
               playerCard?.viewModel.distanceToHole = Float(currentShot.distanceToPin)
               playerCard?.viewModel.ballLiePosition = SIMD3<Float>(currentShot.lie ?? SIMD3(0,0,0))
               let indexOfCurrentShot = playedHole.shots.firstIndex(where: {$0.shotId == currentShot.shotId })
               if indexOfCurrentShot == playedHole.teeShotIndex {
                  showTeeboxCard(player: player, show: false)
               }
               // Show player card only if balltraces are shown.
               if playerNode.ballTraces.last?.isEnabled ?? true {
                  playerCard?.show()
               }
            }
         }
      }
   }
   @objc private func handleTap(recognizer:UITapGestureRecognizer) {
      if self.greenModelEntity?.handleTap(recognizer) ?? false {
         return
      }
      let tapLocation = recognizer.location(in: self.arViewController.arView)
      let _ = self.isClickedOnPlayerCards(tapLocation: tapLocation)
   }
   private func isClickedOnPlayerCards(tapLocation: CGPoint)-> Bool {
      guard let ec = self.experienceConfig else { return false }
      if let customComponent = arViewController.arView.getTappedEntity(tapLocation: tapLocation, maxRange: (ec.arElementMaxRange) ?? 1000) {
         if let player = getPlayerFromEntityName(name: customComponent.name ?? "") {
            let playerDictEntry: [String: golfPlayer] = ["player": player]
            NotificationCenter.default.post(name: Notification.Name(constants.onTappedNotification),
               object: nil,
               userInfo: playerDictEntry)
            return true
         } else {
            return false
         }
      }
      return false
   }
   
   private func getPlayerFromEntityName(name: String) -> golfPlayer? {
      let playerInfo = name.components(separatedBy: "_")
      if playerInfo.count > 1 {
         if let round = Int(playerInfo[0]), let playerId = Int(playerInfo[1]), let requiredRound = self.sportData?.rounds[round - 1] {
            let groups = requiredRound.groups
            var players:[golfPlayer] = []
            groups.forEach { group in
               players.append(contentsOf: group.value.players)
            }
            let requiredPlayer = players.filter{$0.pid == playerId}
            return requiredPlayer.first
            
         }else {
            return nil
         }
      }else {
         return nil
      }
   }
   private func getPlayerColorsFromHexValues(playerColorsInHex:[String]?) -> [UIColor]? {
      if let hexColors = playerColorsInHex {
         if(!hexColors.isEmpty) {
            var colors:[UIColor] = []
            for color in hexColors {
               colors.append(UIColor(hexString: color))
            }
            return colors
         }
      }
      return nil
   }
   private func setTapGesture() {
      DispatchQueue.main.async {
         let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
         self.arViewController.arView.isUserInteractionEnabled = true
         self.arViewController.arView.addGestureRecognizer(tapGestureRecognizer)
      }
   }
   private func getModelConfig() -> [String: Any]? {
      if let aruiViewData = self.arViewController.arUiConfig.data["arUiView"] as? [String: Any]  {
         if let experienceData = aruiViewData["experiences"] as? [[String:Any]] {
            for experience in experienceData {
               if let modelConfig = experience["model"] as? [String:Any] {
                  return modelConfig
               }
            }
         }
      }
      return nil
   }
   private func hideLivePlayerReplay(player: golfPlayer) {
      if let playerRelatedNode = playerRelatedNodes.filter({ $0.player == player }).first {
         playerRelatedNode.isReplayButtonTapped = false
         playerRelatedNode.greenPlayerCard?.hide()
         playerRelatedNode.ballTraces.forEach { ballTrace in
            ballTrace.isEnabled = false
         }
         playerRelatedNode.apexNode?.isEnabled = false
      }
      greenModelEntity?.setReplayButtonTappedStatus(player: player, replayButtonTapped: false)
      // Hide elements from model.
      if let greenModelARElement = greenModelEntity?.playersData.filter({ greenModelPlayerData in
         greenModelPlayerData.player == player
      }).first {
         greenModelARElement.ballTraces.forEach { ballTrace in
            ballTrace.isEnabled = false
         }
      }
   }
   private func replayLivePlayer(player: golfPlayer){
      if let playerRelatedNode = playerRelatedNodes.filter({ $0.player == player}).first {
         playerRelatedNode.greenPlayerCard?.hide()
         playerRelatedNode.apexNode?.hide()
         playerRelatedNode.animateBallTrace()
         playerRelatedNode.isReplayButtonTapped = true
      }
      greenModelEntity?.prepareToAnimate(player: player)
      greenModelEntity?.setReplayButtonTappedStatus(player: player, replayButtonTapped: true)
   }
   private func getHighestPositionedTracePoint(trace:[qVector3])->qVector3{
      if let highest = trace.max(by: { $0.z < $1.z }){
         return highest
      }
      return qVector3(0,0,0)
   }
   private func getApexDataForReplay(player: Q.golfPlayer, currentShot: Q.golfShot)-> (height: Float?, Speed: Float?) {
      var apexHeight: Float?
      var ballSpeed: Float?
      if let currentHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let shots = player.playedHoles.first(where: {$0.num == currentHole.num})?.shots {
         if shots.firstIndex(of: currentShot) == shots.count - 1 {
            apexHeight = Float(currentShot.apexHeight)
            ballSpeed = Float(currentShot.speed)
         } else {
            apexHeight = 0.0
            ballSpeed = 0.0
         }
      }
      return (apexHeight,ballSpeed)
   }
   private func getPlayerScoreForReplayBasedOnShot(player: Q.golfPlayer, currentShot: Q.golfShot) -> Int? {
      if let currentHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == currentHole.num}) {
         
         if ((playedHole.shots.firstIndex(of: currentShot)) == playedHole.shots.count - 1) {
            return (playedHole.scoreAfterHole != nil) ? playedHole.scoreAfterHole : player.score
         } else {
            return playedHole.scoreAtTee
         }
      }
      return nil
   }
   private func beginObserve() {
      NotificationCenter.default.addObserver(self, selector: #selector(onPlayerDataUpdated(_:)), name: Notification.Name(Q.constants.playerDidChangeNotification), object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(onBallTraceAnimationCompleted(_:)), name: Notification.Name(constants.ballTraceAnimationDidCompleteNotification), object: nil)
   }
   private func endObserve() {
      NotificationCenter.default.removeObserver(self, name: Notification.Name(constants.ballTraceReplayDidCompleteNotification), object: nil)
      NotificationCenter.default.removeObserver(self, name: Notification.Name(Q.constants.playerDidChangeNotification), object: nil)
   }
   private func removeAllApexCards() {
      golfApexCardEntity?.removeAllApexCards()
      golfApexCardEntity?.removeFromParent()
      apexNodeDict = [:]
      hiddenTracesApexNodes.removeAll()
   }
   private func removeAllHoleoutCards() {
      self.playerCardModels.forEach { playerCardModel in
         playerCardModel.playerCardEntity.removeAllHoleoutCards()
         playerCardModel.playerCardEntity.removeFromParent()
      }
      self.playerCardModels.removeAll()
   }
   private func removeApexCard(apexcard: golfApexCard) {
      golfApexCardEntity?.hideApexCard(apexcard: apexcard)
      for (index,apexCard) in hiddenTracesApexNodes.enumerated() {
         if (apexcard == apexCard) {
            hiddenTracesApexNodes.remove(at: index)
         }
      }
      apexNodeDict.removeValue(forKey: apexcard)
      if apexNodeDict.isEmpty {
         golfApexCardEntity?.removeFromParent()
      } else {
         changeApexCardPosition()
      }
   }
   private func removeTeeBoxCard(player: golfPlayer) {
      for (index,item) in teeBoxNodes.enumerated(){
         if player == item.viewModel.playerViewModel.player {
            teeBoxNodes[index].removeFromParent()
            teeBoxNodes.remove(at: index)
            break
         }
      }
   }
   private func showTeeboxCard(player: golfPlayer, show: Bool) {
      for (index,item) in teeBoxNodes.enumerated() {
         if player == item.viewModel.playerViewModel.player {
            if show {
               teeBoxNodes[index].show()
            } else {
               teeBoxNodes[index].hide()
            }
            resetPlayerCardsHeightMultiplier()
            break
         }
      }
   }
   private func showApexCard(player: golfPlayer, show: Bool) {
      for (index,item) in playerRelatedNodes.enumerated() {
         if player == item.player,
            let apexNode = playerRelatedNodes[index].apexNode,
            let apexCards = golfApexCardEntity?.apexCards {
            
            if show {
               if let currentCourse = sportData?.currentCourse,
                  let selectedHole = currentCourse.featuredHoles.first( where: {$0.fop == self.fop} ),
                  let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}),
                  let teeShotIndex = playedHole.teeShotIndex {
                  
                  let teeShot = playedHole.shots[teeShotIndex]
                  if teeShot.apexHeight != 0.0 &&
                     teeShot.speed != 0.0 &&
                     !apexCards.contains(apexNode) {
                     
                     golfApexCardEntity?.addApexCard(apexcard:apexNode)
                     apexNode.show()
                  }
               }
            } else {
               golfApexCardEntity?.hideApexCard(apexcard: apexNode)
               apexNode.hide()
            }
            break
         }
      }
   }
   private func showBallTrace(player: golfPlayer, show: Bool) {
      for (index,item) in playerRelatedNodes.enumerated() {
         if player == item.player {
            for ballTrace in playerRelatedNodes[index].ballTraces {
               ballTrace.isEnabled = show
               if let apexNode = playerRelatedNodes[index].apexNode {
                  var isApexNode = false
                  //when hiding traces the apexnodes are added to a array and removes from the array when traces unhided
                  for (index,apexCard) in hiddenTracesApexNodes.enumerated() {
                     if (apexCard == apexNode) {
                        if show {
                           hiddenTracesApexNodes.remove(at: index)
                           changeApexCardPosition()
                        } else {
                           isApexNode = true
                        }
                     }
                  }
                  if !isApexNode && !show {
                     hiddenTracesApexNodes.append(apexNode)
                     changeApexCardPosition()
                     //setting last hided trace position to apexcard
                     if(hiddenTracesApexNodes.count == playerRelatedNodes.count) {
                        let lastPoint = apexNodeDict[hiddenTracesApexNodes[playerRelatedNodes.count - 1]]
                        golfApexCardEntity?.setApexPosition(apexPosition: lastPoint ?? qVector3.zero)
                     }
                  }
               }
            }
            break
         }
      }
      greenModelEntity?.setVisibilityOfBallTraces(player: player, show: show)
      greenModelEntity?.showPlayerCard(player: player)
   }
   private func isPlayerInLiveGroup(player: golfPlayer) -> Bool {
      
      if let currentCourse = sportData?.currentCourse, let currentRoundNum = sportData?.currentRound?.num {
         if let selectedHole = currentCourse.featuredHoles.first( where: {$0.fop == self.fop} ),
            let liveGroupNum = selectedHole.liveGroups.first,
            let liveGroup = sportData?.rounds[ currentRoundNum - 1].groups[ liveGroupNum ] {
            
            if liveGroup.players.compactMap { $0 }.filter({ $0 == player}).count > 0 {
               return true
            }
            return false
         }
      }
      return false
   }
   private func loadPlayerNodes(for player: golfPlayer, isGroupReplay: Bool = false, shotIndexForGroupReplay: Int? = 0, isLiveDataUpdate: Bool = false) {
      removePlayerRelatedNode(player: player)
      
      DispatchQueue.main.async {
         let playerAssociatedData = golfPlayerGreenAssociatedData(player: player)
         playerAssociatedData.greenPlayerCard = self.loadBallIndicatorPlayerCard(player: player)
         playerAssociatedData.greenPlayerCard?.hide()
         
         playerAssociatedData.apexNode = self.loadApexDisplayNode(player: player)
         if self.golfApexCardEntity == nil {
            self.golfApexCardEntity = golfApexCardBaseEntity(arView: self.arViewController.arView, cardFont:playerAssociatedData.apexNode?.cardFont ?? defaults.apexCardBoldFontFamily ,cardSize: playerAssociatedData.apexNode?.cardSize ?? 0.02)
         }
         playerAssociatedData.apexNode?.hide()
                  
         if isGroupReplay {
            if let balltrace = self.getBallTrace(player: player, shotIndex: shotIndexForGroupReplay ?? 0, playerRelatedNode: playerAssociatedData, isLiveDataUpdate: isLiveDataUpdate, isGroupReplay: isGroupReplay) {
               playerAssociatedData.ballTraces = [balltrace]
               let teeBoxCardDelay = Double(self.experienceConfig?.teeBoxCardAppearDelay ?? defaults.teeBoxCardAppearDelay)
               self.teeBoxCardAnimationTimer = Timer.scheduledTimer(withTimeInterval: Double(teeBoxCardDelay), repeats: false, block: { [weak self](timer) in
                   guard self != nil else{return}
                   DispatchQueue.main.async {
                       self?.loadTeeBoxCard(player: player)
                   }
               })
               if let teeBoxCardAnimationTimer = self.teeBoxCardAnimationTimer {
                  RunLoop.main.add(teeBoxCardAnimationTimer, forMode: .common)
               }
            }
         } else {
            playerAssociatedData.ballTraces = self.addBallTraces(player: player, playerRelatedNode: playerAssociatedData, isLiveDataUpdate: isLiveDataUpdate )
            DispatchQueue.main.async {
                self.loadTeeBoxCard(player: player)
            }
         }
         
         let animationDelay = isGroupReplay ? self.experienceConfig?.groupPlayAnimationDelay ?? defaults.groupPlayAnimationDelay :self.experienceConfig?.autoBallTraceAnimationDelay ?? defaults.autoBallTraceAnimationDelay
         if isGroupReplay {
            self.animationTimer = Timer.scheduledTimer(withTimeInterval: Double(animationDelay), repeats: false, block: { [weak self](timer) in
               guard self != nil else{return}
               DispatchQueue.main.async {
                  playerAssociatedData.greenPlayerCard?.hide()
                  playerAssociatedData.animateBallTrace()
               }
            })
         } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(animationDelay)) {
               playerAssociatedData.greenPlayerCard?.hide()
               playerAssociatedData.animateBallTrace()
            }
         }
         
         if let animationTimer = self.animationTimer {
             RunLoop.main.add(animationTimer, forMode: .common)
         }
         
         self.playerRelatedNodes.append(playerAssociatedData)
      }
   }
   private func updatePlayerNodes(for player: golfPlayer, isGroupReplay: Bool = false, shotIndexForGroupReplay: Int? = 0) {
      for (index,item) in playerRelatedNodes.enumerated() {
         if let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
            let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}), item.player == player {
            
            let playerRelatedNode = playerRelatedNodes[index]
            if item.player == player,
               let ballIndicatorPlayerCard = playerRelatedNode.greenPlayerCard {
                  
               // When distanceToPin == 0 it is after hole. Otherwise take the values at tee.
               var playerScore: Int?
               let shot = isGroupReplay ? playedHole.shots[shotIndexForGroupReplay ?? 0] : playedHole.shots.last
               if (shot?.distanceToPin != 0) {
                  playerScore = playedHole.scoreAtTee
               } else {
                  playerScore = (playedHole.scoreAfterHole != nil) ? playedHole.scoreAfterHole : player.score
               }
               ballIndicatorPlayerCard.viewModel.totalScore = playerScore
               
               if let shot = shot {
                  ballIndicatorPlayerCard.viewModel.shotDistance = Float(shot.distance)
                  ballIndicatorPlayerCard.viewModel.shotNumber = isGroupReplay ? shotIndexForGroupReplay ?? 0 + 1 : playedHole.shots.count
                  if !isGroupReplay {
                     if let ballLiePosition = playedHole.shots.last?.lie {
                        ballIndicatorPlayerCard.viewModel.ballLiePosition = SIMD3<Float>(ballLiePosition)
                     }
                  }
               }
            }
               
            // Check whether there are any new shots
            if playedHole.shots.count != playerRelatedNode.ballTraces.count {
               // Check whether its his first shot
               // In that case if the tee order from the server is different, the card shown at tee box wont be his card
               // So we need to show his card at tee box
               if playerRelatedNode.ballTraces.count == 0 {
                  loadTeeBoxCard(player: player)
               }
                  
               var newlyAddedTraces: [ballPath] = []
               if isGroupReplay {
                  if let ballTrace = self.getBallTrace(player: player, shotIndex: shotIndexForGroupReplay ?? 0, playerRelatedNode: playerRelatedNode, isLiveDataUpdate: true, isGroupReplay: isGroupReplay) {
                     newlyAddedTraces.append(ballTrace)
                  }
               } else {
                  newlyAddedTraces = self.addBallTraces(player: player, playerRelatedNode: playerRelatedNode, isLiveDataUpdate: true)
               }
                                    
               if !newlyAddedTraces.isEmpty {
                  if playerRelatedNode.ballTraces.count == 0 && self.liveTeeshotAnimationOngoingPlayers.firstIndex(of: player.pid ) == nil {
                     liveTeeshotAnimationOngoingPlayers.append(player.pid)
                  }
                  
                  if isGroupReplay {
                     let animationDelay = Double(self.experienceConfig?.puttTraceAnimationDelay ?? defaults.puttTraceAnimationDelay)
                      self.animationTimer = Timer.scheduledTimer(withTimeInterval: Double(animationDelay), repeats: false, block: { [weak self](timer) in
                          guard self != nil else{return}
                          DispatchQueue.main.async {
                              playerRelatedNode.animateNewBallTrace(newTraces: newlyAddedTraces)
                          }
                      })
                     if let animationTimer = self.animationTimer {
                         RunLoop.main.add(animationTimer, forMode: .common)
                     }
                  } else {
                     playerRelatedNode.animateNewBallTrace(newTraces: newlyAddedTraces)
                     playerRelatedNode.greenPlayerCard?.hide()
                     playerRelatedNode.apexNode?.hide()
                  }
               }
            }
         }
      }
   }
   private func loadAllPlayerNodes(players: [golfPlayer]) {
      self.removeAllApexCards()
      self.removeAllHoleoutCards()
      playerRelatedNodes.forEach({$0.removeAllAssociatedElementsFromScene()})
      playerRelatedNodes.removeAll()
      players.forEach({
         loadPlayerNodes(for: $0)
      })
   }
   private func updatePlayerRelatedNodesPosition() {
      self.golfApexCardEntity?.setApexCardPosition()
      self.playerCardModels.forEach { playerCardModel in
         playerCardModel.playerCardEntity.setHoleOutCardPosition()
      }
      playerRelatedNodes.forEach {
         $0.greenPlayerCard?.applyCorrectionMatrix()
         // No need to update the position of ball trace as it is already in the PGA Tour coordinate system.
      }
   }
   private func loadTeeBoxPlayerCard(player: golfPlayer) -> golfTeeBoxPlayerCard? {
      if let featuredHole = sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let roundNum = player.team?.round.num {
         let viewModel = golfTeeboxViewModel(
            playerViewModel: playerViewModel(player: player, primaryColor:  UIColor( hexString:player.colors.first?.hexString ?? "#FF0000")),// player.getPrimaryColor()
            roundNum: roundNum,
            teeBoxPosition: qVector3(featuredHole.roundHoleDetails[roundNum - 1].teeBoxLocation),
            score: player.playedHoles.first(where: {$0.num == featuredHole.num})?.scoreAtTee,
            teeBoxScale: Float(getBallTraceConfig().teeBoxCardScale ?? defaults.teeBoxCardScale),
            maxTeeBoxScale: Float(getBallTraceConfig().maxTeeBoxCardScale ?? defaults.maxTeeBoxCardScale),
            smallTeeBoxCardTextSize: getBallTraceConfig().smallTeeBoxCardTextSize ?? defaults.smallTeeBoxCardTextSize,
            smallTeeBoxCardTextFont: getBallTraceConfig().smallTeeBoxCardTextFont ?? defaults.teeBoxCardBoldFontFamily,
            bigTeeBoxCardTextSize: getBallTraceConfig().bigTeeBoxCardTextSize ?? defaults.bigTeeBoxCardTextSize,
            bigTeeBoxCardTextFont: getBallTraceConfig().bigTeeBoxCardTextFont ?? defaults.teeBoxCardBoldFontFamily
         )
         return addTeeBoxCardToScene(with: viewModel)
      }
      return nil
   }
   private func loadBallIndicatorPlayerCard(player: golfPlayer) -> golfGreenPlayerCard {
      var shotNumber: Int = 0
      var lastShot: Q.golfShot? = nil // TODO: Are we guaranteed to have a shot at this point?
      var scoreAtTee: Int? = player.score
      var scoreAfterHole: Int? = nil
      var ballLiePosition: SIMD3<Double>? = nil
      if let featuredHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == featuredHole.num}) {
         
         shotNumber = playedHole.shots.count
         lastShot = playedHole.shots.last
         scoreAtTee = playedHole.scoreAtTee
         scoreAfterHole = playedHole.scoreAfterHole
         ballLiePosition = playedHole.shots.last?.lie
      }
      let lastShotDistance = Float(lastShot?.distance ?? 0)
      let distanceToHole = Float(lastShot?.distanceToPin ?? 0)
      let roundNum = player.team?.round.num ?? -1
        
      let playerStatCardData = golfGreenViewModel(
         playerViewModel: playerViewModel<Q.golfPlayer>(player: player, primaryColor:  UIColor( hexString:player.colors.first?.hexString ?? "#FF0000") ), // getPrimaryColor())
         roundNum: roundNum,
         totalScore: player.score,
         scoreAtTee: scoreAtTee,
         scoreAfterHole: scoreAfterHole,
         shotNumber: shotNumber,
         shotDistance: lastShotDistance,
         distanceToHole: distanceToHole,
         ballLiePosition: ballLiePosition != nil ? SIMD3<Float>(ballLiePosition!) : SIMD3<Float>(0,0,0),
         playerCardScale: getBallTraceConfig().playerStatCardScale ?? defaults.playerStatCardScale,
         maxPlayerCardScale: getBallTraceConfig().maxPlayerStatCardScale ?? defaults.maxPlayerStatCardScale,
         bigGreenCardTextSize: getBallTraceConfig().bigGreenCardTextSize ?? defaults.bigGreenCardTextSize,
         bigGreenCardTextFont: getBallTraceConfig().bigGreenCardTextFont ?? defaults.teeBoxCardBoldFontFamily,
         smallGreenCardTextSize: getBallTraceConfig().smallGreenCardTextSize ?? defaults.smallGreenCardTextSize,
         smallGreenCardTextFont: getBallTraceConfig().smallGreenCardTextFont ?? defaults.smallGreenPlayerCardFont
      )
      if !self.playerCardModels.contains(where: { playerCardModel in
         playerCardModel.position == playerStatCardData.ballLiePosition
      }) {
         let playerCardData = playerCardModel(entity: golfGreenPlayerCardBaseEntity(arView: self.arViewController.arView), position: playerStatCardData.ballLiePosition)
         self.rootAnchor.addChild(playerCardData.playerCardEntity)
         self.playerCardModels.append(playerCardData)
      }
      return addPlayerStatCard(with: playerStatCardData)
   }
   private func loadApexDisplayNode(player: golfPlayer) -> golfApexCard {
      var lastShot: Q.golfShot? = nil
      if let featuredHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == featuredHole.num}) {
         lastShot = playedHole.shots.last
      }
      let lastShotApexHeight = Float(lastShot?.apexHeight ?? 0.0)
      let lastShotSpeed = Float(lastShot?.speed ?? 0.0)
      let roundNum = player.team?.round.num ?? -1
        
      let apexDisplayInfo = golfApexViewModel(
         playerViewModel: playerViewModel<Q.golfPlayer>(player: player, primaryColor:  UIColor( hexString:player.colors.first?.hexString ?? "#FF0000") ), // getPrimaryColor())
         apexPosition: qVector3(0,0,0),
         apexHeight: lastShotApexHeight,
         ballSpeed: lastShotSpeed,
         apexScale: getBallTraceConfig().apexScale ?? defaults.apexScale,
         roundNum: roundNum,
         maxApexScale: getBallTraceConfig().maxApexScale ?? defaults.maxApexScale,
         apexCardDetailsFont: getBallTraceConfig().apexCardDetailsFont ?? defaults.apexCardBoldFontFamily,
         apexCardDetailsFontSize: getBallTraceConfig().apexCardDetailsFontSize ?? defaults.apexCardDetailsFontSize,
         apexCardUnitFontSize: getBallTraceConfig().apexCardUnitFontSize ?? defaults.apexCardUnitFontSize,
         apexCardUnitFont: getBallTraceConfig().apexCardUnitFont ?? defaults.apexCardMedFontFamily,
         apexCardHeadFont: getBallTraceConfig().apexCardHeadFont ?? defaults.apexCardBoldFontFamily,
         apexCardHeadFontSize: getBallTraceConfig().apexCardHeadFontSize ?? defaults.apexCardHeadFontSize
      )
      return addApexDisplayNode(with: apexDisplayInfo)
   }
   private func getBallTrace( player: golfPlayer, shotIndex: Int, playerRelatedNode: golfPlayerGreenAssociatedData, isLiveDataUpdate:Bool, isGroupReplay: Bool = false ) -> golfShot? {
      if let featuredHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == featuredHole.num}) {
         
         let currentShot = playedHole.shots[shotIndex]
         let shotType = currentShot.type
         let vm = golfShotViewModel(player: player, shot: currentShot, isFromGreenContainer: false, isPuttTrace: (shotType == .PUTT))
         vm.radius = (((shotIndex != 0) ? getBallTraceConfig().puttThickness ?? defaults.puttThickness : getBallTraceConfig().flightThickness ?? defaults.flightThickness))
         vm.opacity = Float(getBallTraceConfig().opacity ?? defaults.shotOpacity)
         vm.color = UIColor( hexString:player.colors.first?.hexString ?? "#FF0000")
         
         // If trace is empty join the lie position of previous shot and current shot
         var dummyTrace = [SIMD3<Float>]()
         if currentShot.trace.isEmpty && currentShot.lie != nil {
            if shotIndex != 0 {
               let previousShot = playedHole.shots[shotIndex - 1]
               
               // If the previous shot is not on green, then we don't need to connect the lie positions
               if let previousShotLie = previousShot.lie, let currentShotLie = currentShot.lie {
                  // No need to connect the penalty shot
                  if !playedHole.shots[shotIndex].penalty {
                     dummyTrace.append(SIMD3<Float>(previousShotLie))
                     
                     let intermediatePoints = SIMD3<Float>.createIntermediatePoints(startPoint: SIMD3<Float>(previousShotLie), endPoint: SIMD3<Float>(currentShotLie), numIntermediatePoints: 10)
                     
                     for itemintermediatePoint in intermediatePoints {
                        dummyTrace.append(itemintermediatePoint)
                     }
                  }
                  dummyTrace.append(SIMD3<Float>(currentShotLie))
               }
            }
            vm.waypoints = dummyTrace
         } else {
            // Check for penalty case
            if currentShot.penalty {
               // Add a dummy trace for penalty
               if let currentShotLie = currentShot.lie {
                  dummyTrace.append(SIMD3<Float>(currentShotLie))
               }
               vm.waypoints = dummyTrace
            } else {
               vm.waypoints = currentShot.trace.map { SIMD3<Float>($0) }
               
            }
         }
         
         let ballTrace = golfShot(viewModel: vm)
         
         // Show dotted line for shot that hit water
         ballTrace.isDotted = (playedHole.shots[shotIndex].lieTurf == "Water")
         
         // Check whether it's replay or data update in live
         if !isLiveDataUpdate {
            // To sync the start of ball trace animation in model with real ball trace animation
            // Handlded only for replay right now
            if let teeShotIndex = playedHole.teeShotIndex {
               if( shotIndex == teeShotIndex ) {
                  ballTrace.ballTraceAnimationProgress = onBallTraceAnimationProgress
               }
            }
         } else if userMode == .LIVE_LIVE {
            lastLivePlayer = player
         }
         
         var minPointsCountForBallTraceFading = defaults.minPointsCountForBallTraceFading
         vm.fadeInPercentage = defaults.shotFadeInPercentage
         vm.fadeOutPercentage = defaults.shotFadeOutPercentage
         
         switch shotType {
            case .TEE:
               minPointsCountForBallTraceFading = getBallTraceConfig().minPointsCountForBallTraceFading ?? defaults.minPointsCountForBallTraceFading
               vm.fadeInPercentage = getBallTraceConfig().fadeInPercentage
               vm.fadeOutPercentage = getBallTraceConfig().fadeOutPercentage
               vm.animationSpeed =  getBallTraceConfig().flightAnimationSpeed ?? defaults.flightAnimationSpeed
            case .PUTT:
               minPointsCountForBallTraceFading = getBallTraceConfig().minPointsCountForPuttTraceFading ?? defaults.minPointsCountForPuttTraceFading
               vm.fadeInPercentage = getBallTraceConfig().puttTraceFadeInPercentage ?? defaults.puttTraceFadeInPercentage
               vm.fadeOutPercentage = getBallTraceConfig().puttTraceFadeOutPercentage ?? defaults.puttTraceFadeOutPercentage
               ballTrace.greenPlayerCard = playerRelatedNode.greenPlayerCard
               vm.animationSpeed =  getBallTraceConfig().puttTraceAnimationSpeed ?? defaults.puttTraceAnimationSpeed
            case .CHIP:
               minPointsCountForBallTraceFading = getBallTraceConfig().minPointsCountForChipTraceFading ?? defaults.minPointsCountForChipTraceFading
               vm.fadeInPercentage = getBallTraceConfig().chipTraceFadeInPercentage ?? defaults.chipTraceFadeInPercentage
               vm.fadeOutPercentage = getBallTraceConfig().chipTraceFadeOutPercentage ?? defaults.chipTraceFadeOutPercentage
               vm.animationSpeed = getBallTraceConfig().chipTraceAnimationSpeed ?? defaults.chipTraceAnimationSpeed
            default: break
         }
         
         // Check whether we need to enable fading
         if playedHole.shots[shotIndex].trace.count > minPointsCountForBallTraceFading {
            ballTrace.hasFade = true
         } else {
            ballTrace.hasFade = false
         }
         ballTrace.isGroupReplay = isGroupReplay
         
         if userMode == .LIVE_LIVE && isLiveDataUpdate {
            // In live mode when a player's putt trace comes hide the ball traces of all players including the player who
            // putts and show only the ball lie indicator card of player who putt
            for playerNode in playerRelatedNodes {
               if !playerRelatedNode.isReplayButtonTapped &&
                     playerNode.isReplayButtonTapped &&
                     (playerNode.player != lastLivePlayer || (shotType == .PUTT)) {
                  
                  for ballTrace in playerNode.ballTraces {
                     ballTrace.isEnabled = false
                  }
                  playerNode.apexNode?.isEnabled = false
                  
                  // Hide the playercard of all players except the one who putts
                  if (shotType == .PUTT) {
                     if playerNode.player != lastLivePlayer {
                        playerNode.greenPlayerCard?.hide()
                     } else {
                        playerNode.greenPlayerCard?.show()
                     }
                  }
               }
            }
            greenModelEntity?.playersData.forEach { greenModelPlayerData in
               if !playerRelatedNode.isReplayButtonTapped &&
                     !greenModelPlayerData.isReplayButtonTapped &&
                     (greenModelPlayerData.player != lastLivePlayer || (shotType == .PUTT)) {
                  for ballTrace in greenModelPlayerData.ballTraces {
                     ballTrace.isEnabled = false
                  }
                  
                  // Hide the playercard of all players except the one who putts
                  if shotType == .PUTT {
                     if greenModelPlayerData.player != lastLivePlayer {
                        greenModelPlayerData.hidePlayerCard()
                     } else {
                        greenModelPlayerData.showPlayerCard()
                     }
                  }
               }
            }
         }
         
         if dummyTrace.isEmpty {
            validateAndAddApexCard(player: player,
               shot: playedHole.shots[shotIndex],
               shotIndex: shotIndex,
               apexNode: playerRelatedNode.apexNode,
               tracePoints: playedHole.shots[shotIndex].trace.map {qVector3($0)},
               ballTrace: ballTrace)
         }
         self.worldRootEntity.addChild(ballTrace)
         return ballTrace
      }
      return nil
   }
   private func addBallTraces(player: golfPlayer, playerRelatedNode: golfPlayerGreenAssociatedData, isLiveDataUpdate: Bool) -> [golfShot] {
      var newlyAddedTraces:[golfShot] = []
      if let featuredHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == featuredHole.num}) {

         if playedHole.shots.count >= playerRelatedNode.ballTraces.count {
            for shotIndex in (playerRelatedNode.ballTraces.count) ..< playedHole.shots.count {
               if let ballTrace = self.getBallTrace(player: player,
                  shotIndex: shotIndex,
                  playerRelatedNode: playerRelatedNode,
                  isLiveDataUpdate:isLiveDataUpdate,
                  isGroupReplay: false) {
                  newlyAddedTraces.append(ballTrace)
               }
            }
         }
      }
      return newlyAddedTraces
   }
   private func addTeeBoxCardToScene(with data: golfTeeboxViewModel) -> golfTeeBoxPlayerCard {
      var visbileCardsCount = 0
      if userMode != .LIVE_LIVE {
         for teeBoxNode in teeBoxNodes {
            if teeBoxNode.isEnabled {
               visbileCardsCount = visbileCardsCount + 1
            }
         }
      }
      
      let teeBoxCard = golfTeeBoxPlayerCard(
         model: data,
         arView: arViewController.arView,
         isLiveMode: userMode == .LIVE_LIVE,
         heightMultipler: visbileCardsCount
      )
      self.rootAnchor.addChild(teeBoxCard)
      teeBoxCard.show()
      return teeBoxCard
   }
   private func addPlayerStatCard(with data: golfGreenViewModel) -> golfGreenPlayerCard {
      guard let golfGreenPlayerCardModel = self.playerCardModels.filter({ playerCardModel in
         playerCardModel.position == data.ballLiePosition
      }).first else {return golfGreenPlayerCard()}
      let playerCard = golfGreenPlayerCard(
         model: data,
         arView: self.arViewController.arView,
         heightMultiplier: playerRelatedNodes.count,
         golfGreenPlayerCardBaseEntity: golfGreenPlayerCardModel.playerCardEntity
      )
      playerCard.hide()
      self.rootAnchor.addChild(playerCard)
      return playerCard
   }
   private func addApexDisplayNode(with data: golfApexViewModel) -> golfApexCard {
      let apexDisplayNode = golfApexCard(
         model: data,
         arView: arViewController.arView)
      return apexDisplayNode
   }
   private func isDeviceOrientationReadyForTracking() -> (isDeviceOrientationReady: Bool, isPointedTowardsSky: Bool) {
      guard let sensor = sensor else {
         return (true, true)
      }
       
      let roll = abs(sensor.deviceRollAngle)
      let tiltLimitHigh = self.experienceConfig?.tiltLimitHigh ?? defaults.tiltLimitHigh
      let tiltLimitLow = self.experienceConfig?.tiltLimitLow ?? defaults.tiltLimitLow
      if (roll > (steadyAngle + tiltLimitHigh ) || roll < (steadyAngle - tiltLimitLow)) {
         return (false, roll > (steadyAngle + tiltLimitHigh ))
      } else {
         return (true, roll > (steadyAngle + tiltLimitHigh ))
      }
   }
   private func loadGreenModel() {
      if let modelConfig = getModelConfig() {
         if let url = modelConfig["url"] as? String {
            self.greenModelEntity = golfGreenContainer(parentEntity: self.rootAnchor, arViewController: self.arViewController)
            greenModelEntity?.loadModel(modelUrl: url, initialScale: Float(modelConfig["scale"] as? Double ?? defaults.modelScale))
            
            if let minScale = modelConfig["minScale"] as? Float {
               greenModelEntity?.minScale = minScale
            }
            
            if let maxScale = modelConfig["maxScale"] as? Float {
               greenModelEntity?.maxScale = maxScale
            }
            
            if let maxDistance = modelConfig["maxDistance"] as? Float {
               greenModelEntity?.maxDistanceFromCamera = maxDistance
            }
         }
      }
   }
   private func validateAndShowApexNode(_ player: golfPlayer, _ playerNode: golfPlayerGreenAssociatedData) {
      if let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}),
         let teeShotIndex = playedHole.teeShotIndex {

         if playedHole.shots.count > teeShotIndex {
            // Apex should be shown always based on the tee shot
            let teeShot = playedHole.shots[teeShotIndex]
            if teeShot.apexHeight != 0.0 && teeShot.speed != 0.0 {
               playerNode.apexNode?.show()
            } else {
               playerNode.apexNode?.hide()
            }
         }
      }
   }
   private func startLiveMode() {
      userMode = .LIVE_LIVE
   }
   private func stopLiveMode() {
      userMode = .REPLAY
      
      // Remove all AR elements from Green Model.
      greenModelEntity?.removeAllPlayerNodes()
   }
   private func resetPlayerCardsHeightMultiplier() {
      if userMode != .LIVE_LIVE {
         var visbileTeeboxCardsCount = 0
         for teeBoxPlayerRelatedNode in teeBoxNodes {
            if teeBoxPlayerRelatedNode.isEnabled {
               teeBoxPlayerRelatedNode.setHeightMultiplier(heightMultiplier: visbileTeeboxCardsCount)
               visbileTeeboxCardsCount = visbileTeeboxCardsCount + 1
            }
         }
         
         for (index, element) in playerRelatedNodes.enumerated() {
            element.greenPlayerCard?.setHeightMultiplier(heightMultiplier: index)
         }
      }
   }
   private func loadTeeBoxCard(player: golfPlayer) {
      // If the tee card is already shown for the same player we don't need to show it again.
      if teeBoxNodes.count > 0 && teeBoxNodes[0].viewModel.playerViewModel.player == player {
         return
      }
      
      // In live mode we need to show only one teebox card, so remove all others
      // In replay mode we need to keep all the existing replay teebox cards
      if userMode == .LIVE_LIVE {
         teeBoxNodes.forEach({$0.removeFromParent()})
         teeBoxNodes.removeAll()
      }
      
      if let teeBoxPlayerRelatedData = loadTeeBoxPlayerCard(player:player) {
         teeBoxNodes.append(teeBoxPlayerRelatedData)
      }
   }
   private func validateAndAddApexCard(player: Q.golfPlayer,
      shot: Q.golfShot?,
      shotIndex: Int,
      apexNode: golfApexCard?,
      tracePoints: [qVector3],
      ballTrace: golfShot) {
      
      if let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == self.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}) {
         
         if let teeShotIndex = playedHole.teeShotIndex,
            let currentShot = shot {
            
            if playedHole.shots.count > teeShotIndex &&
               teeShotIndex == shotIndex {
               
               let apexPoint = self.getHighestPositionedTracePoint(trace: tracePoints)
               ballTrace.setApexPoint(apexPoint: apexPoint)
               if currentShot.apexHeight != 0.0 && currentShot.speed != 0.0 {
                  apexNode?.update(height: Float(currentShot.apexHeight), speed: Float(currentShot.speed))
                  ballTrace.setApex(apexNode: apexNode)
               } else {
                  ballTrace.setApexNode(apexNode: apexNode)
               }
            }
         }
      }
   }
   private func updateTeeBoxPlayerCardsPosition() {
      teeBoxNodes.forEach {
         $0.applyCorrectionMatrix()
      }
   }
}
