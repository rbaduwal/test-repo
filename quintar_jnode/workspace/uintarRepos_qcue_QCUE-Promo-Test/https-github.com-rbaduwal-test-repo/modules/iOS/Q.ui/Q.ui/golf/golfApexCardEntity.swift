import Combine
import UIKit
import simd
import Q

class golfApexCardBaseEntity: sceneGraphNode {
   var apexinformationPlane: qModelEntity = qModelEntity()
   var apexRootEntity: qModelEntity = qModelEntity()
   var cardRootEntity: qModelEntity = qModelEntity()
   var basePlane: qModelEntity = qModelEntity()
   var heightMultiplier: Int = 0
   var font: qMeshResource.Font = qMeshResource.Font()
   weak private var arView: qARView?
   var apexCards:[golfApexCard] = []
   var currentCardHeight: Float = 0.27 * constants.golfCardSizeMultiplier
   var apexCardPosition: qVector3? = nil
   var positionUpdated: Bool = false
   private var cardPivot = qVector3(0, 0, 0)
   private var updateSubscription: Cancellable?
   let bluecolor = UIColor(hexString: "#003A70")
   var apexCardSize: Double = 0.02
   var apexCardFont: String = defaults.apexCardBoldFontFamily
   
   init(arView: qARView?,cardFont: String,cardSize: Double) {
      super.init()
      self.arView = arView
      guard let apexTextFont = ObjectFactory.shared.arTextSmallFont else {return}
      self.font = apexTextFont
      self.createGolfCardArrow()
      self.createGolfCard()
      
      self.addChild(cardRootEntity)
      setBillboardConstraints()
      self.apexCardSize = cardSize
      self.apexCardFont = cardFont
   }
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   func addApexCard(apexcard:golfApexCard) {
      if !apexCards.contains(apexcard) { apexCards.append(apexcard); }
      heightMultiplier = apexCards.count - 1
      self.basePlane.addChild(apexcard)
      updatePosition(apexcard:apexcard, islast: true)
      self.show()
   }
   func hideApexCard(apexcard:golfApexCard) {
      var isCardRemoved : Bool = false
      for (index,apexCard) in apexCards.enumerated() {
         if (apexcard == apexCard) {
            apexCards.remove(at: index)
            isCardRemoved = true
         }
         if isCardRemoved {
            heightMultiplier = index - 1
            if(apexCards.count != index) {
               updatePosition(apexcard:apexCard, islast: false)
            } else {
               updatePosition(apexcard:apexCard, islast: true)
            }
         }
      }
      if apexCards.count == 0 {
         self.hide()
      }
   }
   func removeAllApexCards() {
      apexCards.removeAll()
   }
   
   func updatePosition(apexcard:golfApexCard, islast: Bool) {
      var positionInScene : Float = 0.0
      currentCardHeight = ((apexcard.playerDetailsPlain.model?.mesh.bounds.extents.y ?? (0.37*constants.golfCardSizeMultiplier)) * (apexcard.playerDetailsPlain.scale.y))
      positionInScene = Float(heightMultiplier) * currentCardHeight
      positionInScene = positionInScene + 0.045*constants.golfCardSizeMultiplier
      apexcard.setPosition(qVector3(0, positionInScene, 0.00001), relativeTo: self.basePlane)
      if islast {
         let position = positionInScene + currentCardHeight
         self.apexRootEntity.setPosition(qVector3(0,position,0.00001), relativeTo: self.basePlane)
      }
   }
   
   func createGolfCard() {
      apexRootEntity = qModelEntity(mesh: qMeshResource.generateBox(width: 0.32 * constants.golfCardSizeMultiplier, height: 0.038 * constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.4))])
      apexinformationPlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.31 * constants.golfCardSizeMultiplier, height: 0.031 * constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: .white.withAlphaComponent(0.9))])
      apexRootEntity.addChild(apexinformationPlane)
      apexinformationPlane.position = qVector3(0,0,0.001)
      
      let teeShotFont = (UIFont (name: apexCardFont, size: apexCardSize * CGFloat(constants.golfCardSizeMultiplier)) ?? .systemFont(ofSize: 0.01 * CGFloat(constants.golfCardSizeMultiplier), weight: .semibold))
      let teeShotText = qMeshResource.generateText("Tee Shot", extrusionDepth: 0.002, font:teeShotFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      let teeboxTextEntity = qModelEntity(mesh: teeShotText, materials: [qUnlitMaterial(color: bluecolor)])
      apexinformationPlane.addChild(teeboxTextEntity)
      let xExtentForTeeBoxEntity = apexinformationPlane.model!.mesh.bounds.min.x+0.007 * constants.golfCardSizeMultiplier+(teeboxTextEntity.model?.mesh.bounds.extents.x ?? 0)/2
      teeboxTextEntity.setPositionForText( SIMD3<Float> (Float(xExtentForTeeBoxEntity), 0, 0.00001), relativeTo: apexinformationPlane, withFont: teeShotFont)
      
      let apexText = qMeshResource.generateText("Apex", extrusionDepth: 0.002, font: teeShotFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      let apexEntity = qModelEntity(mesh: apexText, materials: [qUnlitMaterial(color:bluecolor)])
      apexinformationPlane.addChild(apexEntity)
      apexEntity.setPositionForText( SIMD3<Float> (Float(0.05 * constants.golfCardSizeMultiplier), 0, 0.00001), relativeTo: apexinformationPlane, withFont: teeShotFont)
      
      let speedText = qMeshResource.generateText("Speed", extrusionDepth: 0.002, font: teeShotFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      let speedEntity = qModelEntity(mesh: speedText, materials: [qUnlitMaterial(color:bluecolor)])
      apexinformationPlane.addChild(speedEntity)
      let xExtentForSpeedEntity = apexinformationPlane.model!.mesh.bounds.max.x-0.02 * constants.golfCardSizeMultiplier-(speedEntity.model?.mesh.bounds.extents.x ?? 0)/2
      speedEntity.setPositionForText( SIMD3<Float> (xExtentForSpeedEntity,0.0,0.00001), relativeTo: apexinformationPlane, withFont: teeShotFont)
      basePlane.addChild(apexRootEntity)
      self.apexRootEntity.setPosition(qVector3(0,0.147*constants.golfCardSizeMultiplier,0.00001), relativeTo: self.basePlane)
   }
   
   func createGolfCardArrow() {
      let image = UIImage(named: "apexBase", in: Bundle(identifier: constants.qUIBundleID), compatibleWith: nil)?.cgImage
      if let convertedCGImage = image {
         let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
         var apexMaterial = qUnlitMaterial()
         apexMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
         basePlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.32 * constants.golfCardSizeMultiplier, height: 0.057 * constants.golfCardSizeMultiplier,depth: 0), materials: [apexMaterial])
         cardPivot.y = ((basePlane.model?.mesh.bounds.extents.y ?? 0.0 )/2.0) * basePlane.scale.y
         cardRootEntity.position = cardPivot
         cardRootEntity.addChild(basePlane)
      }
   }
   
   func setBillboardConstraints() {
      if let arView = self.arView {
         self.setBillboardConstraints(arView: arView, rootEntity: self.cardRootEntity)
      }
      self.distanceToCameraChanged = { distanceToCamera in
         let newScale = min(max(1,distanceToCamera/15),300) * (0.5)
         return qVector3(newScale,newScale,newScale)
      }
   }
   func setApexPosition(apexPosition: qVector3) {
      apexCardPosition = apexPosition
      self.positionUpdated = false
      self.setApexCardPosition()
   }
   func setApexCardPosition() {
      var positionInScene = ObjectFactory.shared.trackingMatrix * SIMD4<Float>(self.apexCardPosition ?? qVector3.zero, 1)
      let apexCardpos:Float = Float(7.0).feetToMeter
      positionInScene.y += apexCardpos
      self.position = qVector3(positionInScene.x, positionInScene.y, positionInScene.z)
   }
}
