import Combine
import UIKit
import simd
import Q

class golfGreenPlayerCardBaseEntity: sceneGraphNode {
   var greenPlayerCardInformationPlane: qModelEntity = qModelEntity()
   var greenPlayerRootEntity: qModelEntity = qModelEntity()
   var cardRootEntity: qModelEntity = qModelEntity()
   var basePlane: qModelEntity = qModelEntity()
   var heightMultiplier: Int = 0
   var font: qMeshResource.Font = qMeshResource.Font()
   weak private var arView: qARView?
   var holeOutCards:[golfSmallGreenPlayerCard] = []
   var currentCardHeight: Float = 0.27 * constants.golfCardSizeMultiplier
   var liePosition: qVector3? = nil
   var positionUpdated: Bool = false
   private var updateSubscription: Cancellable?
   let bluecolor = UIColor(hexString: "#003A70")
   private let leadingOffset: Float = 0.006 * constants.golfCardSizeMultiplier
   
   init(arView: qARView?) {
      super.init()
      self.arView = arView
      guard let apexTextFont = ObjectFactory.shared.arTextSmallFont else {return}
      self.font = apexTextFont
      self.createGolfCardArrow()
      self.createGolfCard()
      
      self.addChild(cardRootEntity)
      self.hide()
      setBillboardConstraints()
      
   }
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   func addHoleOutCard(holeOutCard:golfSmallGreenPlayerCard) {
      let liePosition = holeOutCard.viewModel.ballLiePosition
      setLiePosition(liePosition: qVector3(liePosition))
      if !holeOutCards.contains(holeOutCard) { holeOutCards.append(holeOutCard); }
      heightMultiplier = holeOutCards.count - 1
      self.basePlane.addChild(holeOutCard)
      updatePosition(holeOutCard:holeOutCard, islast: true)
      self.show()
   }
   func hideHoleoutCard(holeOutCard:golfSmallGreenPlayerCard) {
      var isCardRemoved : Bool = false
      for (index,smallGreenPlayerCard) in holeOutCards.enumerated() {
         if (holeOutCard == smallGreenPlayerCard) {
            holeOutCards.remove(at: index)
            holeOutCard.removeFromParent()
            isCardRemoved = true
         }
         if isCardRemoved {
            heightMultiplier = index - 1
            if(holeOutCards.count != index) {
               updatePosition(holeOutCard:smallGreenPlayerCard, islast: false)
            } else {
               updatePosition(holeOutCard:smallGreenPlayerCard, islast: true)
            }
         }
      }
      if holeOutCards.count == 0 {
         self.hide()
      }
   }
   func removeAllHoleoutCards() {
      holeOutCards.removeAll()
   }
   func updatePosition(holeOutCard:golfSmallGreenPlayerCard, islast: Bool) {
      var positionInScene : Float = 0.0
      currentCardHeight = (holeOutCard.basePlane.model?.mesh.bounds.extents.y ?? 1) * holeOutCard.basePlane.scale.y
      positionInScene = Float(heightMultiplier) * currentCardHeight
      positionInScene = positionInScene + 0.03*constants.golfCardSizeMultiplier
      holeOutCard.setPosition(qVector3(0, positionInScene, 0.00001), relativeTo: self.basePlane)
      if islast {
         let position = positionInScene + currentCardHeight + leadingOffset/2
         self.greenPlayerRootEntity.setPosition(qVector3(0,position,0.00001), relativeTo: self.basePlane)
      }
   }
   func createGolfCard() {
      greenPlayerRootEntity = qModelEntity(mesh: qMeshResource.generateBox(width: 0.20 * constants.golfCardSizeMultiplier + (2 * leadingOffset), height: 0.031 * constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.4))])
      greenPlayerCardInformationPlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.20 * constants.golfCardSizeMultiplier, height: 0.027 * constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: .white.withAlphaComponent(0.9))])
      greenPlayerRootEntity.addChild(greenPlayerCardInformationPlane)
      greenPlayerCardInformationPlane.position = qVector3(0,-0.1,0.001)
      
      let puttoutFont = (UIFont (name: defaults.playerCardNormalFontFamily, size: 0.6) ?? .systemFont(ofSize: 0.6, weight: .semibold))
      let puttouttext = qMeshResource.generateText("In the Hole", extrusionDepth: 0.002, font:puttoutFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      let puttoutEntity = qModelEntity(mesh: puttouttext, materials: [qUnlitMaterial(color: UIColor(hexString: "#003A70"))])
      greenPlayerCardInformationPlane.addChild(puttoutEntity)
      let xExtentForHoleEntity = greenPlayerCardInformationPlane.model!.mesh.bounds.min.x+0.007 * constants.golfCardSizeMultiplier+(puttoutEntity.model?.mesh.bounds.extents.x ?? 0)/2
      puttoutEntity.setPositionForText( SIMD3<Float> (Float(xExtentForHoleEntity), 0, 0.001), relativeTo: greenPlayerCardInformationPlane, withFont: puttoutFont)
      
      let scoreText = qMeshResource.generateText("Score", extrusionDepth: 0.002, font:puttoutFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      let scoreEntity = qModelEntity(mesh: scoreText, materials: [qUnlitMaterial(color:  UIColor(hexString: "#003A70"))])
      greenPlayerCardInformationPlane.addChild(scoreEntity)
      let xExtentForScoreEntity = greenPlayerCardInformationPlane.model!.mesh.bounds.max.x - 0.006 * constants.golfCardSizeMultiplier - (scoreEntity.model?.mesh.bounds.extents.x ?? 0)/2
      scoreEntity.setPositionForText( SIMD3<Float> (Float(xExtentForScoreEntity), 0, 0.001), relativeTo: greenPlayerCardInformationPlane, withFont: puttoutFont)
      
      let underLine = qModelEntity(mesh: qMeshResource.generateBox(width: greenPlayerCardInformationPlane.model?.mesh.bounds.extents.x ?? 0.0, height: 0.002 * constants.golfCardSizeMultiplier,depth: 0.0), materials: [qUnlitMaterial(color: UIColor(hexString: "003A70"))])
      greenPlayerCardInformationPlane.addChild(underLine)
      underLine.setPosition(qVector3(0, -(greenPlayerCardInformationPlane.model?.mesh.bounds.extents.y ?? 1)/2, 0.01), relativeTo: greenPlayerCardInformationPlane)
      
      basePlane.addChild(greenPlayerRootEntity)
      self.greenPlayerRootEntity.setPosition(qVector3(0,basePlane.model?.mesh.bounds.max.y ?? 0.147*constants.golfCardSizeMultiplier,0.01), relativeTo: self.basePlane)
   }
   func createGolfCardArrow() {
      let image = UIImage(named: "apexBase", in: Bundle(identifier: constants.qUIBundleID), compatibleWith: nil)?.cgImage
      if let convertedCGImage = image {
         let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
         let holeOutMaterial = qUnlitMaterial()
         holeOutMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
         basePlane = qModelEntity(mesh: qMeshResource.generateBox(size: qVector3(0.20 * constants.golfCardSizeMultiplier + (2 * leadingOffset), 0.030 * constants.golfCardSizeMultiplier, 0.0), cornerRadius: 0.1), materials: [holeOutMaterial])
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
   func setLiePosition(liePosition: qVector3) {
      self.liePosition = liePosition
      self.positionUpdated = false
      self.setHoleOutCardPosition()
   }
   func setHoleOutCardPosition() {
      var positionInScene = ObjectFactory.shared.trackingMatrix * SIMD4<Float>(self.liePosition ?? qVector3.zero, 1)
      let holeOutCardPos:Float = Float(7.0).feetToMeter
      positionInScene.y += holeOutCardPos
      self.position = qVector3(positionInScene.x, positionInScene.y, positionInScene.z)
   }
}
