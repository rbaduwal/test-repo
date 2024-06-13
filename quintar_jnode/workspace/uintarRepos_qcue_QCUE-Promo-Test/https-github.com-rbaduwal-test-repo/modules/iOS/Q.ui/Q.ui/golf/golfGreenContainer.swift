import UIKit
import simd
import Q

class golfGreenContainer: qEntity, qHasModel, qHasCollision {
   
   enum Mode: Int{
      case normal
      case edit
   }
   weak var parentEntity: qEntity?
   weak var arViewController: arUiViewController?
   var rootEntity = qModelEntity()
   var sportsNode = qModelEntity()
   var sportsDataNode = qModelEntity()
   let intialXRotation: Float = 10
   var greenModelCenter = qVector3(0.0,0.0,0.0)
   var currentMode: Mode = .normal
   var initialScale: Float = 0.05
   var cameraAnchor = qRootEntity(.camera)
   var playersData: [golfGreenModelPlayerData] = []
   var entityGestureRecognizers: [qEntityGestureRecognizer]? = nil
   var thicknessOfModel: Float = 0
   var rootEntityLastPositionInLimit = qVector3(0, 0, 0)
   var maxScale: Float = 0.0269
   var minScale: Float = 0.0064
   var maxDistanceFromCamera = Float(3.0)
   var flags: [Int:golfFlag?] = [:]
   
   required init(parentEntity: qEntity, arViewController: arUiViewController) {
      super.init()
      
      self.parentEntity = parentEntity
      self.arViewController = arViewController
      self.rootEntity.addChild(sportsNode)
      self.addChild(rootEntity)
      self.sportsNode.addChild(sportsDataNode)
      self.arViewController?.arView.scene.addAnchor(cameraAnchor)
      NotificationCenter.default.addObserver(self,
         selector: #selector(onBallTraceAnimationCompleted(_:)),
         name: Notification.Name(constants.ballTraceAnimationOnGreenDidCompleteNotification),
         object: nil)
   }
   
   override required init() {
      fatalError("init() has not been implemented")
   }
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   public func loadModel(modelUrl: String, initialScale: Float) {
      if let downloader = self.arViewController?.arUiConfig.downloader as? modelDownloader {
         downloader.getModelAsync(modelUrl) { result in
            if result.error == .NONE {
               if let modelEntity = result.data as? qModelEntity {
                  self.initialScale = initialScale
                  self.sportsNode.addChild(modelEntity)
                  
                  self.rootEntity.transform.scale = qVector3(self.initialScale, self.initialScale, self.initialScale)
                  self.greenModelCenter = modelEntity.model?.mesh.bounds.center ?? qVector3(0.0,0.0,0.0)
                  self.resetTransform()
                  
                  // As we are facing issue while generating collision shape from the model (Collision component is getting misplaced duting the scale operation and when it get misplaced gestures wnt get work)
                  // So create a different shape using the extents of the model
                  // This will be in the sports cooordinate
                  let size = modelEntity.visualBounds(relativeTo: modelEntity).extents
                  var boxShape = qShapeResource.generateBox(size: size)
                  // Get the box correspondimg to AR coordinate
                  boxShape = boxShape.offsetBy(rotation: simd_quatf(angle:-.pi/2, axis: SIMD3<Float>(1,0,0)))
                  // Push the ball traces to the top of the model
                  // Z is the up vector in the sports data coordinate system
                  // size.z = thickness of the model
                  // 0.675 = radius of the ball trace
                  self.thicknessOfModel = size.z
                  self.sportsDataNode.position.z = size.z/2.0 + 0.675
                  
                  self.rootEntity.collision = qCollisionComponent(shapes: [boxShape])
                  self.isEnabled = false
                  NotificationCenter.default.post(name: .modelDownloadingCompleted, object: nil)
               }
            }
         }
      }
   }
   func setgolfGreenContainerForFirstTime() {
      self.parentEntity?.addChild(self)
      self.startEdit()
   }
   func show() -> Void {
      self.isEnabled = true
   }
   func hide() -> Void {
      self.isEnabled = false
      
      // If we are hiding in between edit mode, consider it as cancel,
      // So while showing again open it in edit mode
      cancelModelPlacement()
   }
   func cancelModelPlacement() -> Void {
      if currentMode == .edit{
         currentMode = .normal
         rootEntity.removeFromParent()
         self.removeFromParent()
      }
   }
   fileprivate func removeGestures(_ arView: qARView) {
      if let entityGestureRecognizers = self.entityGestureRecognizers {
         for entityGestureRecognizer in entityGestureRecognizers {
            arView.removeGestureRecognizer( entityGestureRecognizer )
         }
      }
      self.entityGestureRecognizers = nil
   }
   func startEdit() {
      if currentMode == .normal {
         guard let arView = arViewController?.arView else { return }
         NotificationCenter.default.post(name: .onModelPlacementMode, object: nil)
         
         removeGestures(arView)
         
         // While loading in the camera view we need to provide a small rotation in x axis to see the model,
         // otherwise it will be parallel to the camera view
         setTransformForPlacement()
         
         currentMode = .edit
         
         // Remove the model from the PGA tour node
         rootEntity.removeFromParent()
         
         moveToScreenCenter(node:self.rootEntity)
         cameraAnchor.addChild(self.rootEntity)
         
         self.removeFromParent()
         
         self.sportsDataNode.isEnabled = false
      }
   }
   func isInAllowedDistanceFromCamera() -> Bool {
      
      guard let arView = arViewController?.arView else { return true }
      
      let worldTransform = rootEntity.convert(transform: rootEntity.transform, to: nil)
      let distanceFromCamera = abs(distance(worldTransform.matrix.columns.3, arView.cameraTransformMatrix.columns.3))
      
      // Consider the scale
      let scaledMaxDistanceFromCamera = maxDistanceFromCamera * (rootEntity.transform.scale.x / minScale)
      if distanceFromCamera > scaledMaxDistanceFromCamera {
         return false
      } else {
         return true
      }
   }
   @objc func handlePanGesture(gesture: UIGestureRecognizer) {
      if isInAllowedDistanceFromCamera() {
         rootEntityLastPositionInLimit = rootEntity.position
      } else {
         rootEntity.position = rootEntityLastPositionInLimit
      }
   }
   @objc func handleScaleGesture(gesture: UIGestureRecognizer) {
      let scale = rootEntity.scale.x
      // Set the scale to limit if its out of limit
      if scale < minScale {
         rootEntity.scale = qVector3(minScale, minScale, minScale)
      } else if scale > maxScale {
         rootEntity.scale = qVector3(maxScale, maxScale, maxScale)
      }
   }
   
   fileprivate func addGestures(_ arView: qARView) {
      entityGestureRecognizers = arView.installGestures([.translation, .rotation, .scale], for: rootEntity)
      if let entityGestureRecognizers = entityGestureRecognizers {
         for gestureReco in entityGestureRecognizers {
            if gestureReco is qEntityTranslationGestureRecognizer {
               gestureReco.addTarget(self, action: #selector(handlePanGesture(gesture:)))
            } else if gestureReco is qEntityScaleGestureRecognizer {
               gestureReco.addTarget(self, action: #selector(handleScaleGesture(gesture:)))
            }
         }
      }
   }
   fileprivate func placeModel() {
      guard let arView = arViewController?.arView else { return }
      if currentMode == .edit {
         currentMode = .normal
         if let arFrame = arView.session.currentFrame {
            // Calulate the required world position to place uding dummy entity
            let dummyEntity = qEntity()
            let dummyChildEntity = qEntity()
            dummyChildEntity.position = qVector3(0,0,-1)
            dummyEntity.addChild(dummyChildEntity)
            // Get the current camera transform to place the model in the viewing direction
            dummyEntity.transform = qTransform(matrix: arFrame.camera.transform)
            // Get the world postion of the dummyChildEntity and place the model there
            self.rootEntity.position = dummyChildEntity.position(relativeTo: nil)
         }
         
         resetTransform()
         rootEntity.removeFromParent()
         self.addChild(rootEntity)
         parentEntity?.addChild(self)
         self.sportsDataNode.isEnabled = true
         rootEntityLastPositionInLimit = rootEntity.position
         
         addGestures(arView)
         NotificationCenter.default.post(name: .onModelPlacementModeCompleted, object: nil)
      }
   }
   fileprivate func moveToScreenCenter(node: qEntity) {
      node.position =  qVector3(0.0, 0.0,-1.0)
   }
   fileprivate func setTransformForPlacement() {
      
      resetTransform()
      
      rootEntity.transform = qTransform(matrix: simd_float4x4(1))
      self.rootEntity.transform.scale = qVector3(self.initialScale, self.initialScale, self.initialScale)
   }
   fileprivate func resetTransform() {
      
      // Rotate
      var matrix = simd_float4x4(simd_quatf(angle: intialXRotation.degreesToRadians, axis: SIMD3<Float>(1, 0, 0)))
      
      // Transloate
      let modelCenter = SIMD3<Float>(Float(greenModelCenter.x), Float(greenModelCenter.z), Float(-greenModelCenter.y))
      matrix.translate(modelCenter)
      
      // Rotate from PGA Tour to scene coordinate
      matrix.rotate(simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(1, 0, 0)))
      
      sportsNode.transform = qTransform(matrix: matrix)
   }
   func handleTap(_ sender: UITapGestureRecognizer) -> Bool {
      guard let arView = arViewController?.arView else { return false}
      
      let tapRecognizer = sender.location(in: arView)
      let hitTestResults = arView.hitTest(tapRecognizer)
      
      guard let entity = hitTestResults.first?.entity else {
         return false
      }
      
      if (((entity == rootEntity) || isChildNode( rootNode: rootEntity, node: entity ))) {
         if currentMode == .edit {
            placeModel()
         }
         return true
      }
      return false
   }
   fileprivate func isChildNode(rootNode: qEntity, node: qEntity) -> Bool {
      for child in rootNode.children {
         if child == node {
            return true
         }
         
         if( isChildNode( rootNode: child, node: node )) {
            return true
         }
         
      }
      return false
   }
   func addFlag(roundNum: Int) {
      if let currentCourse = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse {
         if let selectedHole = currentCourse.featuredHoles.first( where: {$0.fop == ObjectFactory.shared.sportsVenueController?.fop} ) {
            let pinLocation = selectedHole.roundHoleDetails[roundNum - 1].pinLocation
            if flags[roundNum] as? golfFlag == nil {
               let flag = golfFlag()
               flag.position = qVector3(pinLocation)
               sportsDataNode.addChild(flag)
               flag.show()
               flags[roundNum] = flag
            }
         }
      }
   }
   func onPlayerDataChanged(player: golfPlayer) {
      updatePlayerNode(player: player, animateBallTrace: false)
   }
   func loadPlayerNodes() {
      removeAllPlayerNodes()
      
      if let activePlayers = ObjectFactory.shared.sportsVenueController?.getActivePlayers(){
         loadAllPlayerNodes(players: activePlayers)
      }
   }
   func removeAllPlayerNodes() {
      playersData.forEach({$0.removeAllFromParentNode()})
      playersData.removeAll()
      
      for flag in flags.values {
         if let flag = flag {
            flag.removeFromParent()
         }
      }
      flags.removeAll()
   }
   func removePlayerRelatedNode(player: golfPlayer) {
      for (index,item) in playersData.enumerated() {
         if item.player == player {
            playersData[index].removeAllFromParentNode()
            playersData.remove(at: index)
            break
         }
      }
      
      if let roundNum = player.team?.round.num {
         
         // Check whwther there is any other player from the same round
         var haveOtherPlayersWithSameRound = false
         for (_,item) in playersData.enumerated() {
            if item.player.team?.round.num == roundNum {
               haveOtherPlayersWithSameRound = true
               break
            }
         }
         
         // If all players of the round is removed, then remove its corresponding flag
         if !haveOtherPlayersWithSameRound {
            if let flag = flags[roundNum] {
               flag?.removeFromParent()
               flags.removeValue(forKey: roundNum)
            }
         }
      }
   }
   func setVisibilityOfBallTraces(player: golfPlayer, show: Bool) {
      if let playerNode = playersData.filter({ playerData in
         playerData.player == player
      }).first {
         playerNode.ballTraces.forEach { ballTrace in
            ballTrace.isEnabled = show
         }
      }
   }
   func hidePlayerCard(player: golfPlayer) {
      if let golfGreenModelPlayerData = self.playersData.filter({ playersData in
         playersData.player == player
      }).first {
         golfGreenModelPlayerData.hidePlayerCard()
      }
   }
   func showPlayerCard(player: golfPlayer) {
      if let golfGreenModelPlayerData = self.playersData.filter({ playersData in
         playersData.player == player
      }).first {
         golfGreenModelPlayerData.showPlayerCard()
      }
   }
   func loadAllPlayerNodes(players: [golfPlayer]){
      removeAllPlayerNodes()
      
      players.forEach({
         loadPlayerNode(player: $0)
      })
   }
   func hideARElements(player: golfPlayer) {
      if let playerNode = playersData.filter({ playerData in
         playerData.player == player
      }).first {
         playerNode.ballTraces.forEach { ballTrace in
            ballTrace.isEnabled = true
         }
      }
   }
   func updatePlayerNode(player: golfPlayer, animateBallTrace: Bool){
      if let playerData = self.playersData.filter({ playerNode in
         playerNode.player == player
      }).first {
         if let newlyAddedTraces = self.addBallTraces(player: player, playerData: playerData) {
            if(!newlyAddedTraces.isEmpty) {
               playerData.animateNewBallTrace(newTraces: newlyAddedTraces)
               playerData.showPlayerCard()
            }
         }
      }
   }
   func loadPlayerNode(player: golfPlayer) {
      for (index,item) in playersData.enumerated() {
         if item.player == player {
            playersData[index].removeAllFromParentNode()
            playersData.remove(at: index)
            break
         }
      }
      
      if let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == ObjectFactory.shared.sportsVenueController?.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}),
         let lastLie = playedHole.shots.last?.lie {
         let model = golfGreenViewModel(
            playerViewModel: playerViewModel(player: player, primaryColor:  UIColor( hexString:player.colors.first?.hexString ?? "#FF0000")), // player.getPrimaryColor()
            roundNum: player.team!.round.num,
            totalScore: player.score,
            scoreAtTee: playedHole.scoreAtTee,
            scoreAfterHole: playedHole.scoreAfterHole,
            shotNumber: playedHole.shots.count,
            shotDistance: Float(playedHole.shots.last?.distance ?? 0.0),
            distanceToHole: Float(playedHole.shots.last?.distanceToPin ?? 0),
            ballLiePosition: SIMD3<Float>(lastLie),
            //playerIndex: player.getIndex(),
            playerCardScale: defaults.playerCardScale,
            maxPlayerCardScale: defaults.maxPlayerCardScale,
            bigGreenCardTextSize: defaults.bigGreenCardTextSize,
            bigGreenCardTextFont: defaults.teeBoxCardBoldFontFamily,
            smallGreenCardTextSize: defaults.smallGreenCardTextSize,
            smallGreenCardTextFont: defaults.smallGreenPlayerCardFont
         )
         let playerData = golfGreenModelPlayerData(player: player)
         let playerCardOnGreen = golfGreenModelPlayerCard(model: model,
                                                          arView: self.arViewController?.arView,
                                                          heightMultipler: playersData.count,
                                                          modelThickness: thicknessOfModel)
         playerData.greenModelPlayerCard = playerCardOnGreen
         playerData.hidePlayerCard()
         self.sportsDataNode.addChild(playerCardOnGreen)
         
         if let ballTraces = addBallTraces(player: player, playerData: playerData) {
            playerData.ballTraces = ballTraces
         }
         // For replay, the real ball and the ball trace in the model should animate in sync
         // So no need to start animation while loading, just prepare for animation
         // Animation for the ball trace in the model will start when the real ball trace reach the start point of tee trace in green model
         playerData.prepareToAnimate()
         playersData.append(playerData)
         
         // Check whether a flag is already added for this round
         if let group = player.team, flags[group.round.num] as? golfFlag == nil {
            self.addFlag(roundNum: group.round.num)
         }
      }
   }
   func setReplayButtonTappedStatus(player: golfPlayer,replayButtonTapped: Bool) {
      if let playerNode = playersData.filter({ golfGreenModelPlayerData in
         golfGreenModelPlayerData.player == player
      }).first {
         playerNode.isReplayButtonTapped = replayButtonTapped
      }
   }
   @objc func onBallTraceAnimationCompleted(_ notification: Notification) {
      if let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first(where: {$0.fop == ObjectFactory.shared.sportsVenueController?.fop}),
         let player = notification.userInfo?["player"] as? golfPlayer,
         let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}),
         let shotId = notification.userInfo?["shotID"] as? Int {
         
         self.playersData.forEach { playerData in
            if playerData.player == player,
               let shotIndex = playedHole.shots.firstIndex(where: {$0.shotId == shotId}) {
               
               playerData.greenModelPlayerCard?.viewModel.ballLiePosition = SIMD3<Float>(playedHole.shots[shotIndex].lie ?? SIMD3(0,0,0))
               playerData.greenModelPlayerCard?.update(shotNumber: shotIndex, distance: Float(playedHole.shots[shotIndex].distance))
               playerData.showPlayerCard()
            }
         }
      }
   }
   func getBallTraces(shots: [Q.golfShot]) -> [(path: [SIMD3<Float>], shotID: Int, isPuttTrace: Bool)] {
      var ballTraceDetails = [(path: [SIMD3<Float>], shotID: Int, isPuttTrace: Bool)]()
      for shotIndex in 0 ..< shots.count {
         var ballTrace:([SIMD3<Float>], Int, Bool)
         // First shot will be tee shot
         if shotIndex == 0 {
            var trace = shots[shotIndex].trace
            let pointsCount = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().teeShotPointsCountForGreenModel ?? defaults.teeShotPointsCountForGreenModel
            // For the tee shot we dont need to show full points in the trace in the model
            if trace.count > pointsCount {
               trace = Array(trace.dropFirst(trace.count - pointsCount))
            }
            ballTrace = (trace.map { SIMD3<Float>($0) }, shots[shotIndex].shotId, false)
         } else {
            let shot = shots[shotIndex]
            let previousShot = shots[shotIndex-1]
            var trace: [SIMD3<Float>] = shot.trace.map { SIMD3<Float>($0) }
            if trace.isEmpty {
               if let previousShotLie = previousShot.lie, let currentShotLie = shot.lie {
                  
                  // No need to connect the penalty shot with previous shot lie
                  if !shot.penalty {
                     trace.append(SIMD3<Float>(previousShotLie))
                     
                     let intermediatePoints = SIMD3<Float>.createIntermediatePoints(startPoint: SIMD3<Float>(previousShotLie),
                        endPoint: SIMD3<Float>(currentShotLie),
                        numIntermediatePoints: 10)
                     for itemintermediatePoint in intermediatePoints {
                        trace.append(itemintermediatePoint)
                     }
                  } else {
                     log.instance.push(.INFO, msg: "Penalty shot in green model")
                  }
                  
                  trace.append(SIMD3<Float>(currentShotLie))
               }
            }
            
            ballTrace = (trace, shots[shotIndex].shotId, true)
         }
         ballTraceDetails.append(ballTrace)
      }
      return ballTraceDetails
   }
   func animateBallTrace(player: golfPlayer) {
      if let playerData = self.playersData.filter({ playerNode in
         playerNode.player == player
      }).first {
         playerData.animateBallTrace()
      }
   }
   func prepareToAnimate(player: golfPlayer) {
      for (index,item) in playersData.enumerated(){
         if item.player == player{
            playersData[index].prepareToAnimate()
            playersData[index].isReplayButtonTapped = true
            playersData[index].hidePlayerCard()
         }
      }
   }
   func getStartPointOfTeeTraceInGreenModel(player: golfPlayer) -> SIMD3<Float>? {
      for item in playersData {
         if item.player == player{
            if !item.ballTraces.isEmpty,
               let firstTrace = item.ballTraces.first,
               let point = firstTrace.viewModel.point(atIndex: 0) {
               return point
            }
         }
      }
      return nil
   }
   func onCurrentPlayerChanged(){
      loadPlayerNodes()
   }
   
   fileprivate func animateAllBallTraces() {
      for item in playersData {
         item.animateBallTrace()
      }
   }
   fileprivate func getShotsFromTeeShot(player: Q.golfPlayer) -> [Q.golfShot] {
      if let selectedHole = ObjectFactory.shared.sportsVenueController?.sportData?.currentCourse?.featuredHoles.first( where: {$0.fop == ObjectFactory.shared.sportsVenueController?.fop} ),
         let playedHole = player.playedHoles.first(where: {$0.num == selectedHole.num}) {
         
         if let teeShotIndex = playedHole.teeShotIndex {
            return Array(playedHole.shots.dropFirst(teeShotIndex))
         }
      }
      return []
   }
   fileprivate func addBallTraces(player: Q.golfPlayer, playerData: golfGreenModelPlayerData) -> [golfShot]? {
      let shots = self.getShotsFromTeeShot(player: player)
      let ballTraceDetails = getBallTraces(shots: shots)
      
      if ballTraceDetails.count >= playerData.ballTraces.count {
         if !ballTraceDetails.isEmpty {
            let radius: Float = 0.5
            var newBallTraces:[golfShot] = []
            
            for index in (playerData.ballTraces.count) ..< ballTraceDetails.count {
               // TODO: Hang on to the view model
               let vm = golfShotViewModel(player: player, shot: shots[index], isFromGreenContainer: true, isPuttTrace: ballTraceDetails[index].isPuttTrace)
               vm.waypoints = ballTraceDetails[index].path
               //vm.color = player.color
               vm.opacity = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().opacity ?? defaults.shotOpacity
               vm.radius = radius // TODO: Should come from config
               
               let ballPath = golfShot(viewModel: vm)
               
               self.sportsDataNode.addChild(ballPath)
               newBallTraces.append(ballPath)
            }
            return newBallTraces
         }
      }
      return nil
   }
}
