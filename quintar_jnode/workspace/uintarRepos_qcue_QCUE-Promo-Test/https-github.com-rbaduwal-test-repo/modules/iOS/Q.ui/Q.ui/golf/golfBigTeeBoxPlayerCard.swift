import UIKit
import Combine
import simd
import Q

class golfBigTeeBoxPlayerCard : qEntity, qHasCollision {
   
   private var viewModel: golfTeeboxViewModel
   weak private var arView: qARView? = nil
   private var cardRootEntity: qEntity = qEntity()
   private var playerImagePlane: qModelEntity = qModelEntity()
   private var positionIndicator = playerImage(frame: .init(x: 0, y: 0, width: 500, height: 276))
   private var innerBGPlane: qModelEntity!
   private var playerScoreEntity: qModelEntity!
   private var countryFlagEntity: qModelEntity = qModelEntity()
   private let trailingOffset: Float = 0.005
   private let zPadding: Float = 0.001
   private var updateSubscription: Cancellable?
   let cardPivot: qVector3 = qVector3(0.0, 0.150, 0)
   private var flagIndicator = flagImage(frame: .init(x: 0, y: 0, width: 400, height: 300))
   
   var golfBigTeeBoxPlayerCardFontText: qMeshResource.Font = qMeshResource.Font() //.systemFont(ofSize: 0.03, weight: .bold)
   
   required init( model: golfTeeboxViewModel,
      arView: qARView?) {
      self.viewModel = model
      self.arView = arView
      super.init()
      
      self.viewModel.teeBoxPositionChanged = self.onTeeBoxPositionChanged
      
      self.golfBigTeeBoxPlayerCardFontText = (UIFont (name: viewModel.bigTeeBoxCardTextFont, size: viewModel.bigTeeBoxCardTextSize) ?? .systemFont(ofSize: 0.6, weight: .semibold))
      createCard()
      
      // Attach our data to the entity
      self.setRecursive(withObject: self.viewModel)
      
      // Use recursive collision
      self.generateCollisionShapes(recursive: true)
      for child in self.children {
         child.generateCollisionShapes(recursive: true)
      }
      
      setBillboardConstraints()
      onTeeBoxPositionChanged(teePosition: self.viewModel.teeBoxPosition)
      self.isEnabled = false
   }
   required init?(coder: NSCoder) {
      fatalError("Not implemented")
   }
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   func applyCorrectionMatrix() {
      var positionInScene = ObjectFactory.shared.trackingMatrix * SIMD4<Float>(self.viewModel.teeBoxPosition, 1)
      let distanceToSurface = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().teeBoxCardDistanceToSurface ?? defaults.teeBoxCardDistanceToSurface
      positionInScene.y += Float(distanceToSurface)
      self.position = qVector3(positionInScene.x, positionInScene.y, positionInScene.z)
   }
   
   private func createCard() {
      
      let downloader = httpDownloader()
      // Player image.
      UIImage.fromUrl(url: viewModel.playerViewModel.playerImage, downloader: downloader, completion:{ image in
         if let i = image {
            self.positionIndicator.setData(image: i, borderColor: self.viewModel.playerViewModel.primaryColor, borderWidth: 4)
            let convertedCGImage = self.positionIndicator.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var playerImageMaterial = qUnlitMaterial()
               playerImageMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               self.playerImagePlane.model = qModelComponent(mesh: qMeshResource.generateBox(width: 0.5, height: 0.3,depth: 0,cornerRadius: 0.02), materials: [playerImageMaterial])
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
         self.playerImagePlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.5 * constants.golfCardSizeMultiplier, height: 0.3 * constants.golfCardSizeMultiplier, depth: 0,cornerRadius: 0.02), materials: [playerImageMaterial])
      }
      cardRootEntity.addChild(playerImagePlane)
      
      let bgPlaneWidth: Float = 0.3 * constants.golfCardSizeMultiplier
      let bgPlaneHeight: Float = 0.065 * constants.golfCardSizeMultiplier
      let bgPLaneDepth: Float = 0
      let padding: Float = 0.007 * constants.golfCardSizeMultiplier
      
      let bgPlane = qModelEntity(mesh: qMeshResource.generatePlane(width: bgPlaneWidth, height: bgPlaneHeight, cornerRadius: 0.005), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.3))])
      
      let innerBGPlaneWidth = bgPlaneWidth - padding * 2
      let innerBGPlaneHeight = bgPlaneHeight - padding * 2
      innerBGPlane = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(innerBGPlaneWidth, innerBGPlaneHeight, 0), cornerRadius: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.4))])
      bgPlane.addChild(innerBGPlane)
      innerBGPlane.position.z = bgPLaneDepth / 2 + self.zPadding
      
      UIImage.fromUrl(url: viewModel.playerViewModel.countryFlag, downloader: downloader, completion:{ image in
         if let i = image {
            self.flagIndicator.setData(image: i, borderColor: self.viewModel.playerViewModel.primaryColor, borderWidth: 0)
            let convertedCGImage = self.flagIndicator.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var countryFlagMaterial = qUnlitMaterial()
               countryFlagMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               self.countryFlagEntity.model = qModelComponent(mesh: qMeshResource.generateBox(size: qVector3(0.04 * constants.golfCardSizeMultiplier, 0.03 * constants.golfCardSizeMultiplier, 0)), materials: [countryFlagMaterial])
            }
         }
      })
      
      // Placeholder Flag.
      if let placeHolderFlagImage = UIImage(named: "flag", in: Bundle(identifier:constants.qUIBundleID), with: .none) {
         self.flagIndicator.setData(image: placeHolderFlagImage, borderColor: self.viewModel.playerViewModel.primaryColor, borderWidth: 0)
         let convertedCGImage = self.flagIndicator.asImage().cgImage
         if let convertedCGImage = convertedCGImage {
            let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
            var countryFlagMaterial = qUnlitMaterial()
            countryFlagMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
            self.countryFlagEntity = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(0.04 * constants.golfCardSizeMultiplier, 0.04 * constants.golfCardSizeMultiplier, 0)), materials: [countryFlagMaterial])
         }
      }

      let x: Float = -(innerBGPlaneWidth / 2) + (0.04 * constants.golfCardSizeMultiplier) / 2 + padding
      innerBGPlane.addChild(countryFlagEntity)
      countryFlagEntity.position = qVector3(x, 0, self.zPadding)
      
//        let playerNameEntity = ModelEntity(mesh: .generateText(playerInfo.name, extrusionDepth: 0, font: golfBigTeeBoxPlayerCardFontText, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [UnlitMaterial(color: .white)])
      let playerNameEntity = qModelEntity(mesh: qMeshResource.generateText(viewModel.playerViewModel.name, extrusionDepth: 0, font: golfBigTeeBoxPlayerCardFontText, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      innerBGPlane.addChild(playerNameEntity)
      playerNameEntity.setPosition( qVector3(0.028 * constants.golfCardSizeMultiplier, -0.017 * constants.golfCardSizeMultiplier, self.zPadding), relativeTo: countryFlagEntity)
      
      let stringScore = Q.golfPlayer.score2str(viewModel.score)
      playerScoreEntity = qModelEntity(mesh: qMeshResource.generateText(stringScore, extrusionDepth: 0, font: golfBigTeeBoxPlayerCardFontText, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      
      let bottomLineEntity = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(innerBGPlaneWidth, 0.003 * constants.golfCardSizeMultiplier, 0)), materials: [qUnlitMaterial(color: self.viewModel.playerViewModel.primaryColor)])
      innerBGPlane.addChild(bottomLineEntity)
      bottomLineEntity.position = qVector3(0, -innerBGPlaneHeight / 2, self.zPadding)
      innerBGPlane.addChild(playerScoreEntity)
      let bgPlaneY: Float = (0.3 / 2 + 0.05) * constants.golfCardSizeMultiplier
      bgPlane.setPosition(qVector3(0, bgPlaneY, 0), relativeTo: playerImagePlane)
      cardRootEntity.addChild(bgPlane)
      
      let totalInnerBGPlaneWidth = innerBGPlane.model?.mesh.bounds.extents.x ?? 0.0
      let countryFlagWidth = countryFlagEntity.model?.mesh.bounds.extents.x ?? 0.0
      let playerNameWidth = playerNameEntity.model?.mesh.bounds.extents.x ?? 0.0
      let playerScoreWidth = playerScoreEntity.model?.mesh.bounds.extents.x ?? 0.0
      let textArea = totalInnerBGPlaneWidth - countryFlagWidth
      
      if playerNameWidth + playerScoreWidth + (0.05 * constants.golfCardSizeMultiplier)  >= textArea {
          let spacing = (playerNameWidth + playerScoreWidth - textArea) + 0.05 // extra spacing
          //bgPlane.model?.mesh = .generatePlane(width: bgPlaneWidth + spacing, height: bgPlaneHeight, cornerRadius: 0.005) //???
         bgPlane.model?.mesh = qMeshResource.generatePlane(width: bgPlaneWidth + spacing, height: bgPlaneHeight, cornerRadius: 0.005)
         innerBGPlane.model?.mesh = qMeshResource.generateBox(size: qVector3(totalInnerBGPlaneWidth + spacing, innerBGPlaneHeight, 0))
          countryFlagEntity.position.x -= spacing / 2
         bottomLineEntity.model?.mesh = qMeshResource.generateBox(size: qVector3(totalInnerBGPlaneWidth + spacing, 0.002 * constants.golfCardSizeMultiplier, 0))
          playerNameEntity.position.x -= spacing / 2
          
      }
      let xExtent = innerBGPlane.getMaxBounds()?.x ?? 0 - (playerScoreEntity.getMaxBounds()?.x ?? 0) - padding
      playerScoreEntity.setPosition(qVector3(xExtent, -0.019 * constants.golfCardSizeMultiplier, self.zPadding), relativeTo: innerBGPlane)
      
      cardRootEntity.position = cardPivot
      self.addChild(cardRootEntity)
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
         return qVector3(newScale,newScale,newScale)
      }
   }
}
