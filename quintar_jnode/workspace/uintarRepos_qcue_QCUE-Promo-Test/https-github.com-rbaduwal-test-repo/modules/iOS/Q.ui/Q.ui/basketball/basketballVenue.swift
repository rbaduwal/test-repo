import UIKit
import Combine
import simd
import Q

open class basketballVenue: venue, basketballViewModel {
   
   // basketballViewModel implementation
   public private(set) var sportData: basketballData
   public var selectedPlayers: [basketballPlayer] {
      get { return _selectedPlayers }
      set {
         _selectedPlayers = newValue
         sendChangeNotification()
         self.playersSelected?(_selectedPlayers)
      }
   }
   public var selectedTeam: basketballTeam? {
      get { return _selectedTeam }
      set {
         _selectedTeam = newValue
         sendChangeNotification()
         self.teamSelected?(_selectedTeam)
      }
   }
   public var selectedShotType: basketballShot.SHOT_TYPE {
      get { return _selectedShotType }
      set {
         _selectedShotType = newValue
         sendChangeNotification()
         self.shotTypeSelected?(_selectedShotType)
      }
   }
   public var selectedPeriods: [Int] {
      get { return _selectedPeriods }
      set {
         _selectedPeriods = newValue
         sendChangeNotification()
         self.periodSelected?(_selectedPeriods)
      }
   }
   
   public var playersSelected: (([basketballPlayer ])->())? = nil
   public var teamSelected: ((basketballTeam?)->())? = nil
   public var shotTypeSelected: ((basketballShot.SHOT_TYPE)->())? = nil
   public var periodSelected: (([Int])->())? = nil

   
   // The experience section of the config
   public var experienceConfig: decodableBasketballExperienceConfig.experience?
   
   // Type dividing the court into 4 sections.
   // Looking down from the top, 0 degrees is +x, rotation is counter-clockwise
   public enum QUADRANT: Int {
      case _0 = 0
      case _90
      case _180
      case _270
      case UNKNOWN
   }
   
   // basketballViewModel backing members. We need to capture when a property is set,
   // but if called from an opaque protocol instance swift will NOT call `didset` for properties
   // with automatic storge; thus, we need to have our own backing members here.
   // We'd need these if we used functions instead of properties, so nothing really lost.
   private var _selectedPlayers: [basketballPlayer] = []
   private var _selectedTeam: basketballTeam? = nil
   private var _selectedShotType: basketballShot.SHOT_TYPE = .UNKNOWN
   private var _selectedPeriods: [Int] = []
   
   // Heatmap stuff
   //   private var heatMapRootEntity: Entity = Entity()
   //   private var heatMapModels = [Int:basketballHeatMapSceneGraphNode]()
   //   private var heatMapSceneNode: basketballHeatMapSceneGraphNode?
   //   private var rootHeatMapNodeArray = [Entity]()
   
   // Shot trail stuff
   private var floorTileRootEntity: qEntity = qEntity()
   private var shotTrailsRootEntity: qEntity = qEntity()
   
   // Legend board stuff
   //private var legendBoard: basketballLegendBoardNode?
   
   // Game leaders and player cards
   private var leaderBoard: basketballTeamLeaderBoardNode?
   private var leaderBoardViewSettings = basketballTeamLeaderBoardNode.viewSettings()
   private var playerCardBoard: basketballPlayerCardBoardNode?
   private var playerCardBoardViewSettings = basketballPlayerCardBoardNode.viewSettings()
   private var dataChangeTimer: Timer? = nil // TODO: WHY DO WE NEED THIS???
   private var boardLocation: basketballCourtsideBoard.LOCATION = .COURTSIDE
   private var isTapped = false
   private var boardPositionIndex = 1
   private var isPositionUpdated: Bool = false
   private var courtModel: qModelEntity = qModelEntity()
   
   required public init(arViewController : arUiViewController) throws {
      // sport data is basketball data
      self.sportData = arViewController.sportData as! basketballData
      
      try super.init(arViewController: arViewController)
      self.arViewController.arView.session.delegate = self
      // Load the experience section of the arUiViewConfig, since we are the class which understands this
      if let a = self.arViewController.arUiConfig.data["arUiView"] as? [String: Any] {
         let temp: decodableBasketballExperienceConfig = try parseJson(data: a)
         
         // TODO: pick the first experience for now. We whould be picking the appropriate experience
         experienceConfig = temp.experiences.first
      }
      //      sportData.dataSynced = { _ in
      //         self.updateData()
      //      }
      setTapGesture()
   }
   
   // sportExperience implementation
   override public func createScene() -> qRootEntity {
      _ = super.createScene()
      self.worldRootEntity.addChild(self.shotTrailsRootEntity)
      return self.rootAnchor
   }
   open class override func doesSupportExperience(sport: SPORT, experience: EXPERIENCE) -> Bool {
      return sport == .BASKETBALL && experience == .VENUE
   }
   
   public static func getQuadrant(userPosition: SIMD3<Double>) -> QUADRANT {
      let _2pi = 2.0 * .pi
      
      // Create a vector from center court to the user's position, project along the x/y plane, normalize to a unit vector
      var userVec = userPosition
      userVec.z = 0
      userVec = simd_normalize(userVec)
      
      // Find the angle between 0,0, in radians. atan2 will return the absolute angle as +/-pi, but I want between zero and 2*pi
      let theta = fmod(atan2( userVec.y, userVec.x ) + _2pi, _2pi)
      
      // Quantize the angle into an integer in the set [0-3]
      let quadrantInt = Int(((theta + .pi/4) / (.pi/2)).rounded(.down)) % 4
      
      // Return the quadrant (should always succeed)
      if let quadrant = QUADRANT(rawValue: quadrantInt ) {
         return quadrant
      } else {
         return .UNKNOWN
      }
   }
   
   public override func enableTestModes(_ options: [venue.VENUE_TESTS]) {
      super.enableTestModes(options)
      if (courtModel.parent == nil) {
         loadCourtModel()
      }
      options.contains(.COURT_MODEL) ? (self.courtModel.isHidden = false) : (self.courtModel.isHidden = true)
   }
   
   fileprivate func loadCourtModel() {
         do {
            courtModel = try qEntity.loadModel(named: "court_model_one.usdz")
            courtModel.scale = qVector3(defaults.courtModelScale,defaults.courtModelScale,defaults.courtModelScale)
            self.worldRootEntity.addChild(courtModel)
            courtModel.orientation = qQuaternion(angle:.pi/2, axis: SIMD3<Float>(1,0,0))
            courtModel.position = qVector3(0,0,-constants.zFightBreakup)
            courtModel.isHidden = true
         }catch {
            print("Failed to load model:\(error)")
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
      //  - we are pointing too high
      if ( gravityFail ||
         !isDeviceOrientationReady ||
         arAmbientIntensity < Float(lightEstimationThreshold) && !testModes.contains(.TEST_IMAGE) ||
         isPointedTowardsSky ) {
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
   
   override internal func onTrackingSmoothMoveCompleted(transform: qTransform) ->Void {
      super.onTrackingSmoothMoveCompleted(transform: transform)
      
      // Adding Leaderboard and Playercard for one time
      if isPositionUpdated == false {
         self.updatePlayerCard()
         self.updateLeaderBoard()
         isPositionUpdated = true
      }
      
      // Position the boards
      let viewPosition = self.arViewController.tracker?.viewPosition ?? [0.0, 0.0, 0.0]
      if let board = self.leaderBoard {
         board.animate(to: self.boardLocation, withUserPosition: viewPosition)
      }
      if let board = self.playerCardBoard {
         board.animate(to: self.boardLocation, withUserPosition: viewPosition)
      }
   }
   
   // checking the angle of the device
   fileprivate func isDeviceOrientationReadyForTracking() -> (isDeviceOrientationReady: Bool, isPointedTowardsSky: Bool) {
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
   
   fileprivate func sendChangeNotification() {
      // TODO: What is this timer for?
      dataChangeTimer?.invalidate()
      dataChangeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateData), userInfo: nil, repeats: false)
   }
   
   fileprivate func updateShotTrails() {
      // Remove old traces
      self.shotTrailsRootEntity.removeAllChildren()
      DispatchQueue.global(qos: .background).async {
         
         var selectedShots: [basketballShot] = []
         
         if let team = self.selectedTeam {
            self.sportData.threadSafety.sync {
               for player in team.players {
                  // If we have no selected players *on this team* (team selection), or we have this player (player selection)
                  if self.selectedPlayers.first(where: { $0.team == team }) == nil || self.selectedPlayers.contains(player) {
                     for shot in player.shots {
                        if (self.selectedShotType == shot.type && (self.selectedShotType == .THREE_PTR || self.selectedShotType == .FIELD_GOAL)) ||
                              self.selectedShotType == .TOTAL {
                           
                           // If the shot is for the current period
                           if self.selectedPeriods.firstIndex(where: {$0 == shot.period}) != nil {
                              if shot.trace.count > 0 {
                                 selectedShots.append(shot)
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
         
         // Draw all shot traces when team is selected and draw success shot traces if player is selected
         for (index, shot) in selectedShots.enumerated() {
            if self.selectedPlayers.first(where: { $0.team == self.selectedTeam }) == nil {
               self.addShotTrail(shot: shot, index: index)
            } else {
               if shot.made == true {
                  self.addShotTrail(shot: shot, index: index)
               }
            }
         }
      }
   }
   
   fileprivate func createFloorTile(position: qVector3, shotMade: Bool) -> basketballFloorTileSceneGraphNode {
      let teamShotConfig = (self.selectedTeam == nil || self.selectedTeam!.isHome) ? self.experienceConfig?.homeTeamShot : self.experienceConfig?.awayTeamShot
      
      // Pick color based on whether shot made was success or not
      let floorTileConfig = shotMade ? teamShotConfig?.floorTileSuccess : teamShotConfig?.floorTileAttempt
      
      var floorTileColor: UIColor = .red // Default color if color is not configured
      if let configFloorTileColor = floorTileConfig?.color {
         let floorTileAlpha = floorTileConfig?.opacity ?? defaults.floorTileOpacity
         floorTileColor = UIColor(hexString: configFloorTileColor, alpha: CGFloat(floorTileAlpha))
      }
      
      let floorTileScale = floorTileConfig?.scale ?? defaults.floorTileScale
      
      let floorTileNode = basketballFloorTileSceneGraphNode(color: floorTileColor, scale: Float(floorTileScale))
      floorTileNode.position = position
      return floorTileNode
   }
   
   fileprivate func createShotTrailNode(shot: Q.basketballShot) -> ballPath {
      let teamShotConfig = (self.selectedTeam == nil || self.selectedTeam!.isHome) ? self.experienceConfig?.homeTeamShot : self.experienceConfig?.awayTeamShot
      
      // TODO: We should be creating a viewmodel for each shot once and updating if that shot changes
      // TODO: this view model should know about the shot object
      let vm = ballPathViewModel(shotId: shot.shotId)
      vm.waypoints = utility.array2vec( shot.trace )
      vm.radius = teamShotConfig?.trail?.radius ?? defaults.shotRadius
      vm.color = UIColor(hexString: teamShotConfig?.trail?.color ?? defaults.shotColor)
      vm.opacity = teamShotConfig?.trail?.opacity ?? defaults.shotOpacity
      vm.fadeInPercentage = teamShotConfig?.trail?.fadeInPercentage ?? defaults.shotFadeInPercentage
      vm.fadeOutPercentage = teamShotConfig?.trail?.fadeOutPercentage ?? defaults.shotFadeOutPercentage
      vm.numEdges = defaults.shotNumEdges
      vm.maxNumTurns = 12
      vm.animationSpeed = self.experienceConfig?.shotTrailAnimationDelay ?? defaults.flightAnimationSpeed
      
      return ballPath(viewModel: vm)
   }
   
   fileprivate func addShotTrail(shot: basketballShot, index: Int) {
      if shot.trace.count > 0 {
         DispatchQueue.main.async {
            // Add shot trail
            let shotTrail = self.createShotTrailNode(shot: shot)
            self.shotTrailsRootEntity.addChild(shotTrail)
            
            // Add the floor tile at the first point of shot trail.
            // Apply a small z offset to avoid "z-fighting"
            let floorTilePosition = qVector3(x: Float(shot.origin.x), y: Float(shot.origin.y), z: Float(index) * 0.001)
            self.shotTrailsRootEntity.addChild(self.createFloorTile(position: floorTilePosition, shotMade: shot.made))
            
            // TODO: this is terrible
            shotTrail.prepareToAnimate()
            shotTrail.animationSpeed = shotTrail.viewModel.animationSpeed
            shotTrail.startAnimation(completion: {})
         }
      }
   }
   
   fileprivate func updateHeatMap() {
      
      //      if selectedShotType == .PERIOD {
      //
      //         guard let heatMapConfig = experienceConfig?.experiences.first?.heatmap else {
      //            self.heatMapRootEntity.isEnabled = false
      //            return
      //         }
      //
      //         DispatchQueue.global(qos: .background).async {
      //            var heatMapsPercentageValues = [basketballHeatmap]()
      //
      //            // If a player is selected (selectedPlayerID != -1) then show players heat map info
      //            // If a team is selected (self.selectedPlayerID == -1) then show teams heat map info. Heat map info of the team will have pid = 0
      //            if self.selectedPlayerID != -1 {
      //               // Find the player
      //               var selectedPlayer = self.sportData?.homeTeam?.players.first( where: { $0.pid == self.selectedPlayerID } )
      //               if selectedPlayer == nil {
      //                  selectedPlayer = self.sportData?.awayTeam?.players.first( where: { $0.pid == self.selectedPlayerID } )
      //               }
      //               if let p = selectedPlayer {
      //                  heatMapsPercentageValues.append(contentsOf: p.heatmaps)
      //               }
      //            }
      //            else if let t = self.selectedTeam {
      //               heatMapsPercentageValues.append(contentsOf: t.heatmaps)
      //            }
      ////            let heatMapsData = self.basketballData?.getHeatMaps() ?? []
      ////            for heatMaps in heatMapsData {
      ////               if let teamId = heatMaps["tid"] as? String {
      ////                  let teamIDIntValue = Int(teamId)
      ////                  if teamIDIntValue == self.selectedTeamID {
      ////                     if let playerId = heatMaps["pid"] as? Int {
      ////                        // If a player is selected (selectedPlayerID != -1) then show players heat map info
      ////                        // If a team is selected (self.selectedPlayerID == -1) then show teams heat map info. Heat map info of the team will have pid = 0
      ////                        if ((self.selectedPlayerID != -1) && (playerId == self.selectedPlayerID)) ||
      ////                              ((self.selectedPlayerID == -1) && (playerId == 0)) {
      ////                           heatMapsPercentageValues.append(heatMaps)
      ////                        }
      ////                     }
      ////                  }
      ////               }
      ////            }
      //            self.rootHeatMapNodeArray = []
      //            for (_, keyValue) in self.heatMapModels.enumerated() {
      //               if let zoneIndex = heatMapsPercentageValues.firstIndex(where: {$0.courtIndex == keyValue.key}) {
      //                  for heatMapData in heatMapConfig {
      //                     let heatMapPercentage = heatMapsPercentageValues[zoneIndex].percentage
      //                     if Double(heatMapData.percentage) >= heatMapPercentage {
      //                        let heatMapZoneColor = UIColor(hexString: heatMapData.color, alpha: Float(heatMapData.opacity))
      //                        DispatchQueue.main.async {
      //                           keyValue.value.setZoneColor(color: heatMapZoneColor)
      //                           let textNewEntity = keyValue.value.createTextEntity(text: "\(heatMapPercentage)%",
      //                              font: .boldSystemFont(ofSize: self.percentageTextSize),
      //                              color: UIColor(hexString: self.percentageTextColor, alpha: Float(self.percentageTextOpacity)),
      //                              isSelectedHome: self.selectedTeam?.isHome ?? true,
      //                              courtEntity: self.worldRootEntity)
      //                           self.rootHeatMapNodeArray.append(textNewEntity)
      //                        }
      //                        break
      //                     }
      //                  }
      //               }
      //            }
      //         }
      //
      //         DispatchQueue.main.async {
      //            self.heatMapRootEntity.transform.rotation = simd_quatf(angle: (self.selectedTeam?.isHome ?? true) ? .pi : 0, axis: SIMD3<Float>(0,0,1))
      //            self.heatMapRootEntity.isEnabled = true
      //         }
      //
      //         let legends = createLegends(from: heatMapConfig)
      //         if let team = self.selectedTeam {
      //            addHeatmapBoardEntity(using: legends, teamName: team.name, titleImageName: team.logoUrl)
      //         }
      //
      //      } else {
      //         self.heatMapRootEntity.isEnabled = false
      //         self.removeHeatmapBoardEntity()
      //      }
   }
   fileprivate func createHeatMapEntity() {
      //      let heatmapConfig = self.experienceConfig?.heatmap
      //      let heatMapModelFiles:[Int:String] = [0:"One", 1:"Two",2:"Three", 3:"Four",4:"Five", 5:"Six",6:"Seven", 7:"Eight",8:"Nine", 9:"Ten",10:"Eleven", 11:"Twelve",12:"Thirteen", 13:"Forteen"]
      //
      //      self.worldRootEntity.addChild(self.heatMapRootEntity)
      //
      //      for (_, keyValue) in heatMapModelFiles.enumerated() {
      //         heatMapSceneNode = basketballHeatMapSceneGraphNode(heatMapArView: arViewController.arView)
      //         heatMapSceneNode?.loadModel(name: keyValue.value, scale: SIMD3(x: Float(1.0), y: Float(1.0), z: Float(1.0)))
      //         guard let textNewEntity = heatMapSceneNode?.createTextEntity(text: "000%",
      //            font: .boldSystemFont(ofSize: CGFloat(heatmapConfig?.textSize ?? defaults.heatmapTextSize)),
      //            color: UIColor(hexString: heatmapConfig?.textColor ?? defaults.heatmaptTextColor,
      //               alpha: CGFloat(heatmapConfig?.textOpacity ?? defaults.heatmapTextOpacity)),
      //            isSelectedHome: self.selectedTeam?.isHome ?? true,
      //            courtEntity: worldRootEntity) else { return  }
      //         rootHeatMapNodeArray.append(textNewEntity)
      //         if let modelEntity = heatMapSceneNode?.rootHeatMapNode {
      //            self.heatMapModels[keyValue.key] = heatMapSceneNode
      //            self.heatMapRootEntity.addChild(modelEntity)
      //         }
      //      }
   }
   private func createLegends() -> [Legend] {
      let legends = [Legend]()
      
//      if let heatmapConfig = self.experienceConfig?.heatmap {
//         for (index, heatmapColor) in heatmapConfig.colors.enumerated() {
//            let color = UIColor(hexString: heatmapColor.color ?? defaults.heatmapColor,
//                                alpha: CGFloat(heatmapColor.opacity ?? defaults.heatmapOpacity))
//            if index == 0 {
//               // player
//               legends.append(Legend(text: "0-\(heatmapColor.percentage)%", color: color))
//            } else {
//               // team
//               legends.append(Legend(text: "\(heatmapConfig.colors[index-1].percentage)-\(heatmapColor.percentage)%", color: color))
//            }
//         }
//      }
      
      return legends
   }
   private func addHeatmapBoardEntity(using legends: [Legend], teamName: String, titleImageName: String) {
      //      legendBoard?.removeFromParent()
      //
      //      guard let basketBallConfig = self.experienceConfig?.experiences.first,
      //         let lbpa = basketBallConfig.heatmapBoardPositionA,
      //         let lbpb = basketBallConfig.heatmapBoardPositionB else { return }
      //      self.legendBoardPositionA = lbpa
      //      self.legendBoardPositionB = lbpb
      //
      //      guard let legendBoardConfigurables = basketBallConfig.legendBoardConfigurables else {return}
      //
      //      let endTitle = legendBoardConfigurables.endTitle
      //      let color = legendBoardConfigurables.color
      //      let opacity = legendBoardConfigurables.opacity
      //
      //      legendBoard = basketballLegendBoardNode(
      //         legends: legends,
      //         title: "\(teamName.uppercased()) \(endTitle)",
      //         titleImageName: titleImageName,
      //         backgroundColor: UIColor(hexString: color, alpha: Float(opacity)), arView: arViewController?.arView
      //      )
      //
      //      let totalComponentWidth = legendBoard?.getTotalLegendWidth()
      //      if let totalWidth = totalComponentWidth {
      //         legendBoardPositionA.x = legendBoardPositionA.x + (totalWidth / 2)
      //         legendBoardPositionB.x = legendBoardPositionB.x - (totalWidth / 2)
      //      }
      //
      //      if let legendBoard = legendBoard {
      //         worldRootEntity.addChild(legendBoard)
      //      }
   }
   private func updateLegendBoardPosition(relativeTo cameraPosition: simd_float4) {
      //      guard let legendBoard = self.legendBoard else { return }
      //
      //      let camPosition: SIMD3<Float> = [cameraPosition.x, cameraPosition.y, cameraPosition.z]
      //
      //      // camera position relative to sports root entity
      //      let localCamPos = self.worldRootEntity.convert(position: camPosition, from: nil)
      //
      //      let distanceBtwCamAndPointA = distance(localCamPos, self.legendBoardPositionA)
      //      let distanceBtwCamAndPointB = distance(localCamPos, self.legendBoardPositionB)
      //      if distanceBtwCamAndPointA > distanceBtwCamAndPointB {
      //         legendBoard.transform.rotation = simd_mul(simd_quatf(angle: .pi / 2, axis: [1, 0, 0]), simd_quatf(angle: 0, axis: [0, 1, 0]))
      //         legendBoard.position = self.legendBoardPositionA
      //      } else {
      //         legendBoard.transform.rotation = simd_mul(simd_quatf(angle: .pi / 2, axis: [1, 0, 0]), simd_quatf(angle: .pi, axis: [0, 1, 0]))
      //         legendBoard.position = self.legendBoardPositionB
      //      }
   }
   private func removeHeatmapBoardEntity() {
      //      legendBoard?.removeFromParent()
   }
   private func updatePlayerCard(){
      // Set our generic visual properties
      if let v = self.experienceConfig?.playerCardConfigurables?.backgroundColor { self.playerCardBoardViewSettings.backgroundColor = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.nameFontFamily { self.playerCardBoardViewSettings.nameFontFamily = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.shotTypeFontFamily { self.playerCardBoardViewSettings.shotTypeFontFamily = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.scrFontFamily { self.playerCardBoardViewSettings.scrFontFamily = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.nameSize { self.playerCardBoardViewSettings.nameSize = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.shotTypeSize { self.playerCardBoardViewSettings.shotTypeSize = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.scrSize { self.playerCardBoardViewSettings.scrSize = v }
      if let v = self.experienceConfig?.playerCardConfigurables?.backgroundOpacity { self.playerCardBoardViewSettings.backgroundOpacity = v }
      
      // TODO: dimensions should probably be configurable
      self.playerCardBoardViewSettings.boardHeight = defaults.leaderBoardHeight * 0.9
      
      // Set team-specific visual properties
      if let st = selectedTeam {
         let teamConfig = (st.isHome == true ? self.experienceConfig?.playerCardConfigurables?.playerColors?.homeTeam : self.experienceConfig?.playerCardConfigurables?.playerColors?.awayTeam)
         
         if let v = teamConfig?.highlight { self.playerCardBoardViewSettings.highlightColor = v }
         if let v = teamConfig?.name { self.playerCardBoardViewSettings.nameColor = v }
         if let v = teamConfig?.shotType { self.playerCardBoardViewSettings.shotTypeColor = v }
         if let v = teamConfig?.shotTypeBackground { self.playerCardBoardViewSettings.shotTypeBackgroundColor = v }
         if let v = teamConfig?.success { self.playerCardBoardViewSettings.successColor = v }
         if let v = teamConfig?.attempt { self.playerCardBoardViewSettings.attemptColor = v }
         if let v = teamConfig?.attemptOpacity { self.playerCardBoardViewSettings.attemptOpacity = v }

         // Lazily create our playercard, if needed
         if self.playerCardBoard == nil {
            self.playerCardBoard = basketballPlayerCardBoardNode( model: self, viewSettings: self.playerCardBoardViewSettings, arView: arViewController.arView )
            if let playerCardBoard = self.playerCardBoard {
               playerCardBoard.distanceFromFloor = defaults.courtsideBoardDistanceFromFloor // TODO: need to rethink configurability here
               playerCardBoard.distanceFromCamera = self.experienceConfig?.playerCardConfigurables?.distanceFromCamera ?? defaults.courtsideBoardDistanceFromCamera
               playerCardBoard.animationSpeed = self.experienceConfig?.leaderBoardConfigurables?.duration ?? defaults.courtsideBoardAnimationSpeed
               worldRootEntity.addChild(playerCardBoard)
            }
         }
      }
      
      if let playerCardBoard = self.playerCardBoard {
         // Show/hide the playercard if we have:
         //  - a selected team
         //  - players are selected from that team (otherwise we show game leaders instead)
         //  - have successfully registered once, and any fly-in animations are complete
         //    (see usage of self.successfullyRegisteredOnce)
         if selectedTeam != nil,
            self.selectedPlayers.contains(where: { $0.team == selectedTeam}),
            self.successfullyRegisteredOnce == true {
            
            // Update the playercard
            playerCardBoard.update(vs: self.playerCardBoardViewSettings)
            playerCardBoard.isEnabled = true
         } else {
            playerCardBoard.isEnabled = false
         }
      }
   }
   @objc private func updateData() {
      updateShotTrails()
      
      DispatchQueue.main.async {
         self.updatePlayerCard()
         self.updateLeaderBoard()
         
         // Position the boards
         let viewPosition = self.arViewController.tracker?.viewPosition ?? [0.0, 0.0, 0.0]
         if let board = self.leaderBoard {
            board.animate(to: self.boardLocation, withUserPosition: viewPosition)
         }
         if let board = self.playerCardBoard {
            board.animate(to: self.boardLocation, withUserPosition: viewPosition)
         }
      }
   }
   private func updateLeaderBoard() {
      // Set our generic visual properties
      if let v = self.experienceConfig?.leaderBoardConfigurables?.backgroundColor { self.leaderBoardViewSettings.backgroundColor = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.opacity { self.leaderBoardViewSettings.opacity = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.endTitle { self.leaderBoardViewSettings.endTitle = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.titleSize { self.leaderBoardViewSettings.titleSize = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.titleFontFamily { self.leaderBoardViewSettings.titleFontFamily = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.nameSize { self.leaderBoardViewSettings.nameSize = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.nameFontFamily { self.leaderBoardViewSettings.nameFontFamily = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.scrSize { self.leaderBoardViewSettings.scrSize = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.scrFontFamily { self.leaderBoardViewSettings.scrFontFamily = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.categoryOrder { self.leaderBoardViewSettings.categoryOrder = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.headShotWidth { self.leaderBoardViewSettings.headShotWidth = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.underscoreWidth { self.leaderBoardViewSettings.underscoreWidth = v }
      if let v = self.experienceConfig?.leaderBoardConfigurables?.underscoreHeight { self.leaderBoardViewSettings.underscoreHeight = v }
      
      // Set team-specific visual properties
      if let st = selectedTeam {
         let teamConfig = (st.isHome == true ? self.experienceConfig?.leaderBoardConfigurables?.colors?.hometeam : self.experienceConfig?.leaderBoardConfigurables?.colors?.awayTeam)
         
         if let v = teamConfig?.highlight { self.leaderBoardViewSettings.highlightColor = v }
         if let v = teamConfig?.title { self.leaderBoardViewSettings.titleColor = v }
         if let v = teamConfig?.name { self.leaderBoardViewSettings.nameColor = v }
         if let v = teamConfig?.scr { self.leaderBoardViewSettings.scrColor = v }
         if let v = teamConfig?.underscore { self.leaderBoardViewSettings.underscoreColor = v }
         if let v = teamConfig?.underscoreOpacity { self.leaderBoardViewSettings.underscoreOpacity = v }
         if let v = teamConfig?.titleBackground { self.leaderBoardViewSettings.titleBackgroundColor = v }
         
         // Lazily create our leaderboard, if needed
         if self.leaderBoard == nil {
            self.leaderBoard = basketballTeamLeaderBoardNode( model: self, viewSettings: self.leaderBoardViewSettings, arView: arViewController.arView )
            if let leaderBoard = self.leaderBoard {
               leaderBoard.distanceFromFloor = defaults.courtsideBoardDistanceFromFloor // TODO: need to rethink configurability here
               leaderBoard.distanceFromCamera = self.experienceConfig?.leaderBoardConfigurables?.distanceFromCamera ?? defaults.courtsideBoardDistanceFromCamera
               leaderBoard.animationSpeed = self.experienceConfig?.leaderBoardConfigurables?.duration ?? defaults.courtsideBoardAnimationSpeed
               worldRootEntity.addChild(leaderBoard)
            }
         }
      }
      
      if let leaderBoard = self.leaderBoard {
         // Show/hide the leaderboard if we have:
         //  - a selected team
         //  - no players are selected from that team (otherwise we show player cards instead)
         //  - have successfully registered once, and any fly-in animations are complete
         //    (see usage of self.successfullyRegisteredOnce)
         if selectedTeam != nil,
            !self.selectedPlayers.contains(where: { $0.team == selectedTeam}),
            self.successfullyRegisteredOnce == true {
            
            // Update the leaderboard
            leaderBoard.update(vs: self.leaderBoardViewSettings)
            leaderBoard.isEnabled = true
         } else {
            leaderBoard.isEnabled = false
         }
      }
   }
   private func setTapGesture() {
      DispatchQueue.main.async {
         let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
         self.arViewController.arView.addGestureRecognizer(tapGestureRecognizer)
      }
   }
   @objc private func handleTap(recognizer:UITapGestureRecognizer) {
      let tapLocation = recognizer.location(in: self.arViewController.arView)
      let _ = self.isClickedOnPlayerCards(tapLocation: tapLocation)
   }
   private func isClickedOnPlayerCards(tapLocation: CGPoint) {
      // getTappedEntity return qEntity using hittest method in scenekit and raycast method in Realitykit.
      if let customComponent = arViewController.arView.getTappedEntity(tapLocation: tapLocation, maxRange: 1000) {
         if customComponent.name == defaults.forceNameLeaderboard || customComponent.name == defaults.forceNamePlayercard {
            isTapped = true

            // Toggle the board location
            if boardLocation == .USER { boardLocation = .COURTSIDE } else { boardLocation = .USER }

            // Position the boards
            let viewPosition = self.arViewController.tracker?.viewPosition ?? [0.0, 0.0, 0.0]
            if let board = self.leaderBoard {
               board.animate(to: self.boardLocation, withUserPosition: viewPosition)
            }
            if let board = self.playerCardBoard {
               board.animate(to: self.boardLocation, withUserPosition: viewPosition)
            }
         }
      }
   }
}
