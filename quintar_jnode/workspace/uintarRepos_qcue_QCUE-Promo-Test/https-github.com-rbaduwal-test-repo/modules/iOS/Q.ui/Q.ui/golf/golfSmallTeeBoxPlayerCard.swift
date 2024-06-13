import Combine
import simd
import UIKit
import Q

class golfSmallTeeBoxPlayerCard : sceneGraphNode {
   
   private var viewModel: golfTeeboxViewModel
   weak private var arView: qARView? = nil
   private var cardRootEntity: qEntity = qEntity()
   private var innerBGPlane: qModelEntity!
   private var playerScoreEntity: qModelEntity!
   private var countryFlagEntity: qModelEntity = qModelEntity()
   private let trailingOffset: Float = 0.005
   private let zPadding: Float = 0.001
   private var updateSubscription: Cancellable?
   var heightMultipler:Int = 0
   var cardPivot:qVector3 = qVector3(0, 0, 0)
   let meterToFeet:Float = 3.28
   var golfSmallTeeBoxTextFont: qMeshResource.Font = qMeshResource.Font() //.systemFont(ofSize: 0.03, weight: .bold)
   private var positionIndicator = flagImage(frame: .init(x: 0, y: 0, width: 400, height: 300))
   private var entityName:String = ""
   
   required init( model: golfTeeboxViewModel,
      arView: qARView?,
      heightMultipler: Int) {
      self.viewModel = model
      self.arView = arView
      self.heightMultipler = heightMultipler
      super.init()
      
      self.viewModel.teeBoxPositionChanged = self.onTeeBoxPositionChanged
      
      self.golfSmallTeeBoxTextFont = (UIFont (name: self.viewModel.smallTeeBoxCardTextFont, size: self.viewModel.smallTeeBoxCardTextSize) ?? .systemFont(ofSize: 0.9, weight: .semibold))
      setEntityName()
      createCard()
      
      // Attach our data to the entity
      self.setRecursive(withObject: self.viewModel)
      
      // Use recursive collision
      self.generateCollisionShapes(recursive: true)
      for child in self.children {
         child.generateCollisionShapes(recursive: true)
      }
      
      setBillboardConstraints()
      self.onTeeBoxPositionChanged(teePosition: self.viewModel.teeBoxPosition)
      self.hide()
   }
   
   required init?(coder: NSCoder) {
      fatalError("Not implemented")
   }
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   func setEntityName() {
      let round = self.viewModel.roundNum
      let playerId = self.viewModel.playerViewModel.playerId
      self.entityName = "\(round)_\(playerId)"
   }
   func applyCorrectionMatrix(scale: Float = 1) {
      var positionInScene = ObjectFactory.shared.trackingMatrix * SIMD4<Float>(self.viewModel.teeBoxPosition, 1)
      let currentCardHeight = (innerBGPlane.model?.mesh.bounds.extents.y ?? 0.0) * innerBGPlane.scale.y * scale * 1.6
      positionInScene.y += Float(heightMultipler) * currentCardHeight
      let distanceToSurface = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().teeBoxCardDistanceToSurface ?? defaults.teeBoxCardDistanceToSurface
      positionInScene.y += Float(distanceToSurface)
      self.position = qVector3(positionInScene.x, positionInScene.y, positionInScene.z)
   }
   
   internal func createCard() {
      let bgPlaneWidth: Float = 0.3 * constants.golfCardSizeMultiplier
      let bgPlaneHeight: Float = 0.065 * constants.golfCardSizeMultiplier
      let bgPLaneDepth: Float = 0
      let padding: Float = 0.007 * constants.golfCardSizeMultiplier
      
      let bgPlane = qModelEntity(mesh: qMeshResource.generateBox(width: bgPlaneWidth, height: bgPlaneHeight, depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.7))])
      
      let innerBGPlaneWidth = bgPlaneWidth - padding * 2
      let innerBGPlaneHeight = bgPlaneHeight - padding * 2
      
      innerBGPlane = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(innerBGPlaneWidth, innerBGPlaneHeight, 0), cornerRadius: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.8))])
      bgPlane.addChild(innerBGPlane)
      innerBGPlane.position.z = bgPLaneDepth / 2 + self.zPadding
      
      let downloader = httpDownloader()
      // Country flag.
      UIImage.fromUrl(url: viewModel.playerViewModel.countryFlag, downloader: downloader, completion:{ image in
         if let i = image {
            self.positionIndicator.setData(image: i, borderColor: self.viewModel.playerViewModel.primaryColor, borderWidth: 0)
            let convertedCGImage = self.positionIndicator.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var playerFlagMaterial = qUnlitMaterial()
               playerFlagMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               self.countryFlagEntity.model = qModelComponent(mesh: qMeshResource.generateBox(size: qVector3.init(0.04*constants.golfCardSizeMultiplier, 0.03*constants.golfCardSizeMultiplier, 0)), materials: [playerFlagMaterial])
            }
         }
      })
      
      // Placeholder Image.
      let image = UIImage(named: "flag", in: Bundle(identifier:constants.qUIBundleID), with: .none)
      if let i = image {
         self.positionIndicator.setData(image: i, borderColor: self.viewModel.playerViewModel.primaryColor, borderWidth: 0)
         let convertedCGImage = self.positionIndicator.asImage().cgImage
         if let convertedCGImage = convertedCGImage {
            let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
            var flagMaterial = qUnlitMaterial()
            flagMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
            countryFlagEntity = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(0.04 * constants.golfCardSizeMultiplier, 0.04 * constants.golfCardSizeMultiplier, 0)), materials: [flagMaterial])
         }
      }
      
      let x: Float = -(innerBGPlaneWidth / 2) + 0.02 * constants.golfCardSizeMultiplier + padding
      innerBGPlane.addChild(countryFlagEntity)
      countryFlagEntity.position = qVector3(x,0,self.zPadding)
      
      let playerNameEntity = qModelEntity(mesh: qMeshResource.generateText(viewModel.playerViewModel.name, extrusionDepth: 0, font: golfSmallTeeBoxTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      innerBGPlane.addChild(playerNameEntity)
      let xExtentForName = -(innerBGPlane.model?.mesh.bounds.min.x ?? 0) - (countryFlagEntity.model?.mesh.bounds.extents.x ?? 0) - (playerNameEntity.model?.mesh.bounds.extents.x ?? 0)/2 
      
      playerNameEntity.setPositionForText( SIMD3<Float> (-Float(xExtentForName - 2*padding), 0, self.zPadding), relativeTo: innerBGPlane, withFont: self.golfSmallTeeBoxTextFont)
      
      let stringScore = Q.golfPlayer.score2str(viewModel.score)
      playerScoreEntity = qModelEntity(mesh: qMeshResource.generateText(stringScore, extrusionDepth: 0, font: golfSmallTeeBoxTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      innerBGPlane.addChild(playerScoreEntity)

      
      let bottomLineEntity = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(innerBGPlaneWidth, 0.003 * constants.golfCardSizeMultiplier, 0)), materials: [qUnlitMaterial(color: viewModel.playerViewModel.primaryColor)])
      innerBGPlane.addChild(bottomLineEntity)
      bottomLineEntity.position = qVector3(0,-innerBGPlaneHeight / 2,self.zPadding)
      cardRootEntity.addChild(bgPlane)
      
      let totalInnerBGPlaneWidth = innerBGPlane.model?.mesh.bounds.extents.x ?? 0.0
      let countryFlagWidth = countryFlagEntity.model?.mesh.bounds.extents.x ?? 0.0
      let playerNameWidth = playerNameEntity.model?.mesh.bounds.extents.x ?? 0.0
      let playerScoreWidth = playerScoreEntity.model?.mesh.bounds.extents.x ?? 0.0
      
      let textArea = totalInnerBGPlaneWidth - countryFlagWidth
      
      
      if playerNameWidth + playerScoreWidth + 0.05 * constants.golfCardSizeMultiplier  >= textArea {
          
         let spacing = (playerNameWidth + playerScoreWidth - textArea) + 0.05 * constants.golfCardSizeMultiplier
         bgPlane.model?.mesh = qMeshResource.generateBox(width: bgPlaneWidth, height: bgPlaneHeight, depth: 0)
         innerBGPlane.model?.mesh = qMeshResource.generateBox(size: qVector3(totalInnerBGPlaneWidth + spacing, innerBGPlaneHeight, 0))
         countryFlagEntity.position.x -= spacing / 2
         bottomLineEntity.model?.mesh = qMeshResource.generateBox(size: qVector3(totalInnerBGPlaneWidth + spacing, 0.002 * constants.golfCardSizeMultiplier, 0))
         playerNameEntity.position.x -= spacing / 2
      }
      let xExtentForPlayerScoreEntity = innerBGPlane.model!.mesh.bounds.max.x-0.008 * constants.golfCardSizeMultiplier-(playerScoreEntity.model?.mesh.bounds.extents.x ?? 0)/2
      playerScoreEntity.setPositionForText( SIMD3<Float> (xExtentForPlayerScoreEntity, 0, self.zPadding), relativeTo: innerBGPlane, withFont: self.golfSmallTeeBoxTextFont)

      
      cardPivot.y = ((innerBGPlane.model?.mesh.bounds.extents.y ?? 0.0) / 2.0) * innerBGPlane.scale.y
      cardRootEntity.position = cardPivot
      self.addChild(cardRootEntity)
      self.forceName(self.entityName, recursive: true)
  }
   
   private func onTeeBoxPositionChanged(teePosition: qVector3) {
      applyCorrectionMatrix()
   }
   private func setBillboardConstraints() {
      if let arView = self.arView {
         self.setBillboardConstraints(arView: arView, rootEntity: self.cardRootEntity)
      }
      self.distanceToCameraChanged = { distanceToCamera in
         let newScale = min(max(1,distanceToCamera/15),self.viewModel.maxTeeBoxScale) * (self.viewModel.teeBoxScale)
         self.applyCorrectionMatrix(scale: newScale)
         return qVector3(newScale,newScale,newScale)
      }
   }
}
