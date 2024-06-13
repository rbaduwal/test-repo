import Combine
import simd
import UIKit
import Q

internal class golfBigGreenPlayerCard: sceneGraphNode {
   
   public var viewModel: golfGreenViewModel
   public var heightMultipler: Int = 0
   
   weak private var arView: qARView? = nil
   private let leadingOffset: Float = 0.006 * constants.golfCardSizeMultiplier
   private var playerDetail: qModelEntity = qModelEntity()
   private var playerImagePlane: qModelEntity = qModelEntity()
   private var holeShotPlane: qModelEntity = qModelEntity()
   private var shotValueEntity: qModelEntity = qModelEntity()
   private var shotNumberEntity: qModelEntity = qModelEntity()
   private var gameRound: qModelEntity = qModelEntity()
   private var holeValue: qModelEntity = qModelEntity()
   private var gameScore: qModelEntity = qModelEntity()
   private var positionIndicator = playerImage(frame: .init(x: 0, y: 0, width: 500, height: 276))
   private var updateSubscription: Cancellable?
   //private var playerScoreEntity: ModelEntity!
   private let zPadding: Float = 0.001
   private let trailingOffset: Float = 0.009 * constants.golfCardSizeMultiplier
   private var cardRootEntity = qModelEntity()
   private var smallCard = qModelEntity()
   private let cardPivot: qVector3 = qVector3(0.0, 0.150, 0)
   private var entityName:String = ""
   var font: qMeshResource.Font = qMeshResource.Font()
   
   init( model: golfGreenViewModel,
         arView: qARView?,
         heightMultipler: Int) {
      self.viewModel = model
      self.arView = arView
      self.heightMultipler = heightMultipler
      super.init()
      
      // Observe view model changes
      self.viewModel.totalScoreChanged += ("golfBigGreenPlayerCard", onTotalScoreChanged)
      self.viewModel.shotNumberChanged += ("golfBigGreenPlayerCard", onShotNumberChanged)
      self.viewModel.ballLiePositionChanged += ("golfBigGreenPlayerCard", onBallPositionChanged)
      
      self.font = (UIFont (name: self.viewModel.bigGreenCardTextFont, size: self.viewModel.bigGreenCardTextSize * CGFloat(constants.golfCardSizeMultiplier)) ?? .systemFont(ofSize: 0.03 * CGFloat(constants.golfCardSizeMultiplier), weight: .semibold))
      setEntityName()
      createCard()
      
      // Attach our view model to the entity
      self.setRecursive(withObject: self.viewModel)
      
      // Use recursive collision
      self.generateCollisionShapes(recursive: true)
      for child in self.children {
         child.generateCollisionShapes(recursive: true)
      }
      
      setBillboardConstraints()
      self.onBallPositionChanged(ballPosition: self.viewModel.ballLiePosition)
      self.hide()
      
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
         //NotificationCenter.default.post(name: Notification.Name.onPlayerCardVisibilityChanged, object: nil, userInfo: ["playerId": self.playerStat.playerId, "isVisible": true])
      }
   }
   
   func setEntityName() {
      let round = self.viewModel.roundNum
      let playerId = self.viewModel.playerViewModel.playerId
      self.entityName = "\(round)_\(playerId)"
   }
   
   func applyCorrectionMatrix() {
      var positionInScene = ObjectFactory.shared.trackingMatrix * SIMD4<Float>(self.viewModel.ballLiePosition, 1)
      let distanceToSurface = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().playerStatCardDistanceToSurface ?? defaults.playerStatCardDistanceToSurface
      positionInScene.y += Float(distanceToSurface)
      self.position = qVector3(positionInScene.x, positionInScene.y, positionInScene.z)
      
      // Adjust the height of the small card based on the height multiplier
      let currentCardHeight = smallCard.visualBounds(relativeTo: smallCard).extents.y * 1.2 * Float(heightMultipler)  /* GAP */
      let bgPlaneY: Float = (0.3 / 2 + 0.05) * constants.golfCardSizeMultiplier + currentCardHeight
      smallCard.setPosition(qVector3(0, bgPlaneY, 0), relativeTo: playerImagePlane)
   }
   
   private func onBallPositionChanged(ballPosition: SIMD3<Float>) {
      applyCorrectionMatrix()
   }
   private func onTotalScoreChanged(totalScore: Int?) {
      gameScore.model?.mesh = .generateText(Q.golfPlayer.score2str(totalScore), extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let xExtentForGameScore = playerDetail.model!.mesh.bounds.max.x - trailingOffset - (gameScore.model?.mesh.bounds.extents.x ?? 0)/2
      gameScore.setPositionForText( SIMD3<Float> (Float(xExtentForGameScore), 0, self.zPadding), relativeTo: gameScore.parent, withFont: self.font)
   }
   private func onShotNumberChanged(shotNumber: Int) {
      shotNumberEntity.model?.mesh = .generateText("\(shotNumber)", extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      shotNumberEntity.setPositionForText( SIMD3<Float> (0, 0.035 * constants.golfCardSizeMultiplier, 0), relativeTo: gameScore.parent, withFont: self.font)
   }
   func createCard() {
      let vm = self.viewModel
      
      var score: Int?
      
      if vm.distanceToHole != 0 {
         score = (vm.scoreAtTee != nil) ? vm.scoreAtTee : vm.totalScore
      } else {
         score = (vm.scoreAfterHole != nil) ? vm.scoreAfterHole : vm.totalScore
      }
      
      // get player image asynchronously
      let downloader = httpDownloader()
      
      // Player image.
      UIImage.fromUrl(url: vm.playerViewModel.playerImage, downloader: downloader, completion:{ image in
         if let i = image {
            self.positionIndicator.setData(image: i, borderColor: vm.playerViewModel.primaryColor, borderWidth: 4)
            let convertedCGImage = self.positionIndicator.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var playerImageMaterial = qUnlitMaterial()
               playerImageMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               self.playerImagePlane.model = qModelComponent(mesh: .generateBox(width: 0.5 * constants.golfCardSizeMultiplier, height: 0.3 * constants.golfCardSizeMultiplier,depth: 0,cornerRadius: 0.02), materials: [playerImageMaterial])
            }
         }
      })
      
      // Placeholder player image.
      self.positionIndicator.setData(image: UIImage(named: "defaultPlayer", in: Bundle(identifier:constants.qUIBundleID), compatibleWith: nil)!, borderColor: self.viewModel.playerViewModel.primaryColor, borderWidth: 4.0)
      let image = positionIndicator.asImage().cgImage
      if let convertedCGImage = image {
         let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
         var playerImageMaterial = qUnlitMaterial()
         playerImageMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
         self.playerImagePlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.5 * constants.golfCardSizeMultiplier, height: 0.3 * constants.golfCardSizeMultiplier,depth: 0,cornerRadius: 0.02), materials: [playerImageMaterial])
      }
      
      // shot number
      shotNumberEntity = qModelEntity(mesh: .generateText("\(vm.shotNumber)", extrusionDepth: 0.001, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      
      playerImagePlane.addChild(shotNumberEntity)
      shotNumberEntity.setPositionForText( SIMD3<Float> (0, 0.035 * constants.golfCardSizeMultiplier, 0), relativeTo: gameScore.parent, withFont: self.font)

      cardRootEntity.addChild(playerImagePlane)
      let bgPlaneWidth: Float = 0.3 * constants.golfCardSizeMultiplier
      let bgPlaneHeight: Float = 0.065 * constants.golfCardSizeMultiplier
      let bgPLaneDepth: Float = 0
      let padding: Float = 0.010 * constants.golfCardSizeMultiplier
      
      smallCard = qModelEntity(mesh: .generateBox(width: bgPlaneWidth, height: bgPlaneHeight, depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.7))])
      
      let innerBGPlaneWidth = bgPlaneWidth - padding * 2
      let innerBGPlaneHeight = bgPlaneHeight - padding * 2
      playerDetail = qModelEntity(mesh: .generateBox(size: qVector3(innerBGPlaneWidth, innerBGPlaneHeight, 0), cornerRadius: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.8))])
      smallCard.addChild(playerDetail)
      playerDetail.position.z = (bgPLaneDepth / 2) + self.zPadding
      
      let playerNameEntity = qModelEntity(mesh: .generateText("R\(vm.roundNum) \(vm.playerViewModel.name)", extrusionDepth: 0, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      playerDetail.addChild(playerNameEntity)
      let xExtentForPlayerNameEntity = playerDetail.model!.mesh.bounds.min.x+padding+(playerNameEntity.model?.mesh.bounds.extents.x ?? 0)/2
      playerNameEntity.setPositionForText( SIMD3<Float> (Float(xExtentForPlayerNameEntity), 0, self.zPadding), relativeTo: playerDetail, withFont: self.font)
      
      let stringScore = Q.golfPlayer.score2str(score)
      gameScore = qModelEntity(mesh: .generateText(stringScore, extrusionDepth: 0, font: self.font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      playerDetail.addChild(gameScore)
      let xExtentForGameScore = playerDetail.model!.mesh.bounds.max.x - trailingOffset - (gameScore.model?.mesh.bounds.extents.x ?? 0)/2
      gameScore.setPositionForText( SIMD3<Float> (Float(xExtentForGameScore), 0, self.zPadding), relativeTo: playerDetail, withFont: self.font)
      
      let bottomLineEntity = qModelEntity(mesh: .generateBox(size: qVector3(innerBGPlaneWidth, 0.003 * constants.golfCardSizeMultiplier, 0)), materials: [qUnlitMaterial(color: vm.playerViewModel.primaryColor)])
      playerDetail.addChild(bottomLineEntity)
      bottomLineEntity.position = qVector3(0, -innerBGPlaneHeight / 2, self.zPadding)
            
      let bgPlaneY: Float = (0.3 / 2 + 0.05) * constants.golfCardSizeMultiplier
      smallCard.setPosition(qVector3(0, bgPlaneY, 0.01), relativeTo: cardRootEntity)
      cardRootEntity.addChild(smallCard)
      
      let totalInnerBGPlaneWidth = playerDetail.model!.mesh.bounds.extents.x
      let playerNameWidth = playerNameEntity.model!.mesh.bounds.extents.x
      let playerScoreWidth = gameScore.model!.mesh.bounds.extents.x
      let textArea = totalInnerBGPlaneWidth
      
      if playerNameWidth + playerScoreWidth + 0.05 * constants.golfCardSizeMultiplier  >= textArea {
         let spacing = (playerNameWidth + playerScoreWidth - textArea) + 0.05 * constants.golfCardSizeMultiplier // extra spacing
         smallCard.model?.mesh = .generateBox(width: bgPlaneWidth + spacing, height: bgPlaneHeight, depth: 0)
         playerDetail.model?.mesh = .generateBox(size: qVector3(totalInnerBGPlaneWidth + spacing, innerBGPlaneHeight, 0))
         bottomLineEntity.model?.mesh = .generateBox(size: qVector3(Float(totalInnerBGPlaneWidth + spacing), 0.002 * constants.golfCardSizeMultiplier, 0))
         playerNameEntity.position.x -= spacing / 2
      }
      cardRootEntity.position.y = ((cardRootEntity.visualBounds(relativeTo: cardRootEntity).extents.y)/2.0)
      self.addChild(cardRootEntity)
      self.forceName(self.entityName, recursive: true)
   }
   func setBillboardConstraints() {
      if let arView = self.arView {
         self.setBillboardConstraints(arView: arView, rootEntity: self.cardRootEntity)
      }
      self.distanceToCameraChanged = { distanceToCamera in
         let newScale = min(max(1,distanceToCamera/15),self.viewModel.maxPlayerCardScale) * (self.viewModel.playerCardScale)
         return qVector3(newScale,newScale,newScale)
      }
   }
}
