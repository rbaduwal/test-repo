import Combine
import simd
import UIKit
import Q

internal class golfSmallGreenPlayerCard: sceneGraphNode {
   
   public var viewModel: golfGreenViewModel
  
   weak private var arView: qARView? = nil
   private let widthOfCardInPixel: Float = 600.0
   private let offsetOfIndicator: Float = 28.0
   private let leadingOffset: Float = 0.006 * constants.golfCardSizeMultiplier
   var basePlane: qModelEntity = qModelEntity()
   private var playerDetail: qModelEntity = qModelEntity()
   private var shotDistancePlane: qModelEntity = qModelEntity()
   private var shotDistanceEntity: qModelEntity = qModelEntity()
   private var gameRound: qModelEntity = qModelEntity()
   private var playerName: qModelEntity = qModelEntity()
   private var gameScore: qModelEntity = qModelEntity()
   private var updateSubscription: Cancellable?
   private var playerScoreEntity: qModelEntity!
   private var innerBGPlane: qModelEntity!
   private let zPadding: Float = 0.001
   private let trailingOffset: Float = 0.006 * constants.golfCardSizeMultiplier
   private var cardRootEntity: qEntity = qEntity()
   private var cardPivot = qVector3(0, 0, 0)
   private var entityName: String = ""
   
   var font: qMeshResource.Font = qMeshResource.Font()
   
   init( model: golfGreenViewModel,
         arView: qARView?,
         heightMultipler: Int) {
      self.viewModel = model
      self.arView = arView
      super.init()
      
      // Observe view model changes
      self.viewModel.totalScoreChanged += ("golfSmallGreenPlayerCard", onTotalScoreChanged)
      self.viewModel.shotNumberChanged += ("golfSmallGreenPlayerCard", onShotNumberChanged)
      self.viewModel.ballLiePositionChanged += ("golfSmallGreenPlayerCard", onBallPositionChanged)
      
      self.font = UIFont(name: defaults.teeBoxCardBoldFontFamily, size: 0.6) ?? .systemFont(ofSize: 0.6, weight: .semibold)
      setEntityName()
      createCard()
      
      // Attach our data to the entity
      self.setRecursive(withObject: self.viewModel)
      
      // Use recursive collision
      self.generateCollisionShapes(recursive: true)
      for child in self.children {
         child.generateCollisionShapes(recursive: true)
      }
      
   }
   required init?(coder: NSCoder) {
      fatalError("Not implemented")
   }
   override required init() {
      fatalError("init() has not been implemented")
   }
   override func hide() {
      super.hide()
      
      DispatchQueue.main.async {
         NotificationCenter.default.post(name: Notification.Name(constants.onPlayerCardVisibilityChanged),
            object: nil,
            userInfo: ["playerId": self.viewModel.playerViewModel.playerId, "isVisible": false])
      }
   }
   override func show() {
      super.show()
      
      DispatchQueue.main.async {
         //NotificationCenter.default.post(name: Notification.Name.onPlayerCardVisibilityChanged, object: nil, userInfo: ["playerId": self.viewModel.playerViewModelId, "isVisible": true])
      }
   }
   func setEntityName() {
      let round = self.viewModel.roundNum
      let playerId = self.viewModel.playerViewModel.playerId
      self.entityName = "\(round)_\(playerId)"
   }
   private func onBallPositionChanged(ballPosition: SIMD3<Float>) {
      // TODO: Code for ball position changed
   }
   private func onTotalScoreChanged(totalScore: Int?) {
      gameScore.model?.mesh = .generateText(Q.golfPlayer.score2str(totalScore), extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let xExtentForGameScore = playerDetail.model!.mesh.bounds.max.x - trailingOffset - (gameScore.model?.mesh.bounds.extents.x ?? 0)/2
      gameScore.setPositionForText( SIMD3<Float> (Float(xExtentForGameScore), 0, self.zPadding), relativeTo: gameScore.parent, withFont: self.font)
   }
   private func onShotNumberChanged(shotNumber: Int) {
      // TODO: Assume shotDistance has also been updated
      shotDistanceEntity.model?.mesh = .generateText("\(self.viewModel.shotDistance.convertedToYardAndFeet)", extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let xExtentForShotValue = shotDistancePlane.model!.mesh.bounds.max.x - trailingOffset - (shotDistanceEntity.model?.mesh.bounds.extents.x ?? 0)/2
      shotDistanceEntity.setPositionForText( SIMD3<Float> (Float(xExtentForShotValue), 0, self.zPadding), relativeTo: gameScore.parent, withFont: self.font)
   }
   func createCard() {
      let paneHeight: Float = 0.026 * constants.golfCardSizeMultiplier
      let data = self.viewModel
      var score: Int?
      if data.distanceToHole != 0 {
         score = (data.scoreAtTee != nil) ? data.scoreAtTee : data.totalScore
      } else {
         score = (data.scoreAfterHole != nil) ? data.scoreAfterHole : data.totalScore
      }
      basePlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.20 *  constants.golfCardSizeMultiplier + (2 * leadingOffset), height: paneHeight + 0.2, depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.4))])
      cardRootEntity.addChild(basePlane)
      basePlane.setPosition(qVector3(0, 0, -0.00004), relativeTo: cardRootEntity)
      
      //Right player detail plane
      playerDetail = qModelEntity(mesh: qMeshResource.generateBox(width: 0.20 * constants.golfCardSizeMultiplier, height: paneHeight,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.8))])
      cardRootEntity.addChild(playerDetail)
      
      //Game score
      let gameScoreMesh = qMeshResource.generateText(Q.golfPlayer.score2str(score), extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let gameScoreMaterial = qUnlitMaterial(color: .white)
      gameScore = qModelEntity(mesh: gameScoreMesh, materials: [gameScoreMaterial])
      playerDetail.addChild(gameScore)
      
      //Game team
      let gameRoundDetails = "R\(data.roundNum) "
      let gameRoundMesh = qMeshResource.generateText(gameRoundDetails, extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let gameRoundMaterial = qUnlitMaterial(color: viewModel.playerViewModel.primaryColor)
      gameRound = qModelEntity(mesh: gameRoundMesh, materials: [gameRoundMaterial])
      playerDetail.addChild(gameRound)
      
      //Player name
      let playerNameDetails = "\(data.playerViewModel.player.nameFirstInitialDotLast)"
      let playerNameMesh = qMeshResource.generateText(playerNameDetails,extrusionDepth: 0.001, font: self.font)
      let playerNameMaterial = qUnlitMaterial(color: .white)
      playerName = qModelEntity(mesh: playerNameMesh, materials: [playerNameMaterial])
      playerDetail.addChild(playerName)
      
      let totalNameWidth = playerName.model?.mesh.bounds.extents.x ?? 0.0
      let totalScoreWidth = gameScore.model?.mesh.bounds.extents.x ?? 0.0
      let totalRoundWidth = gameRound.model?.mesh.bounds.extents.x ?? 0.0
      var playerDetailWidth = playerDetail.model?.mesh.bounds.extents.x ?? 0.0
      let extraSpacing: Float = 0.03 * constants.golfCardSizeMultiplier
      
      if totalNameWidth + totalScoreWidth + totalRoundWidth + extraSpacing >= playerDetailWidth {
         let spacing = totalNameWidth + totalScoreWidth + totalRoundWidth + extraSpacing - playerDetailWidth
         playerDetail.model?.mesh = .generateBox(size: qVector3(0.20 * constants.golfCardSizeMultiplier + spacing, paneHeight, 0))
         playerDetailWidth = 0.20 * constants.golfCardSizeMultiplier + spacing
      }
      
      let xExtentForGameRound = playerDetail.model!.mesh.bounds.min.x+leadingOffset+((gameRound.model?.mesh.bounds.extents.x ?? 0)/2)
      gameRound.setPositionForText( SIMD3<Float> (Float(xExtentForGameRound), 0, self.zPadding), relativeTo: gameRound.parent, withFont: self.font)
      let xExtentForPlayerName =
      playerDetail.model!.mesh.bounds.min.x+leadingOffset*4+(gameRound.model?.mesh.bounds.extents.x ?? 0)+((playerName.model?.mesh.bounds.extents.x ?? 0)/2)
      playerName.setPositionForText(SIMD3<Float> (Float(xExtentForPlayerName), 0, self.zPadding), relativeTo: gameRound.parent, withFont: self.font)
      let xExtentForGameScore = playerDetail.model!.mesh.bounds.max.x - trailingOffset - ((gameScore.model?.mesh.bounds.extents.x ?? 0)/2)
      gameScore.setPositionForText( SIMD3<Float> (Float(xExtentForGameScore), 0, self.zPadding), relativeTo: gameScore.parent, withFont: self.font)
      
      //Right player detail underline
      let underLine = qModelEntity(mesh: qMeshResource.generateBox(width: playerDetailWidth, height: 0.002 * constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: viewModel.playerViewModel.primaryColor)])
      playerDetail.addChild(underLine)
      underLine.setPosition(qVector3(0, -(playerDetail.model?.mesh.bounds.extents.y ?? 1)/2, 0.01), relativeTo: playerDetail)
      
      // Shots value
      let shotValueMesh = qMeshResource.generateText("\(data.shotDistance.convertedToYardAndFeet)", extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let shotValueMaterial = qUnlitMaterial(color: .white)
      shotDistanceEntity = qModelEntity(mesh: shotValueMesh, materials: [shotValueMaterial])
      shotDistancePlane.addChild(shotDistanceEntity)
      let xExtentForShotValue = shotDistancePlane.model!.mesh.bounds.max.x - trailingOffset - (shotDistanceEntity.model?.mesh.bounds.extents.x ?? 0)/2
      shotDistanceEntity.setPositionForText( SIMD3<Float> (Float(xExtentForShotValue), 0, self.zPadding), relativeTo: gameScore.parent, withFont: self.font)
      
      self.addChild(cardRootEntity)
      self.forceName(self.entityName, recursive: true)
   }
}
