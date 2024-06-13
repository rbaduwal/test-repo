import Combine
import UIKit

class golfApexCard: sceneGraphNode {
   private let viewModel: golfApexViewModel
   private var apexPosition: qVector3
   private let widthOfCardInPixel: Float = 600.0
   private let offsetOfIndicator: Float = 28.0
   private var cardRootEntity: qEntity = qEntity()
   weak private var arView: qARView?
   private var apexValueEntity: qModelEntity = qModelEntity()
   private var apexRootEntity: qModelEntity = qModelEntity()
   private var speedvalueEntity: qModelEntity = qModelEntity()
   private var apexinformationPlane: qModelEntity = qModelEntity()
   var playerDetailsPlain: qModelEntity = qModelEntity()
   private var apexPlane: qModelEntity = qModelEntity()
   private var speedPlane: qModelEntity = qModelEntity()
   private var apexValueFtEntity: qModelEntity = qModelEntity()
   private var speedValueMphEntity: qModelEntity = qModelEntity()
   private var speedValueFtEntity: qModelEntity = qModelEntity()
   private let trailingOffset: Float = 0.01 * constants.golfCardSizeMultiplier
   private var updateSubscription: Cancellable?
   public var cardFont: String = defaults.apexCardBoldFontFamily
   public var cardSize: Double = 0.02
   private var entityName: String = ""
   
   init(model: golfApexViewModel, arView: qARView?) {
      self.viewModel = model
      self.arView = arView
      self.apexPosition = viewModel.apexPosition
      super.init()
      cardFont = viewModel.apexCardHeadFont
      cardSize = viewModel.apexCardHeadFontSize
      setEntityName()
      createCard()
      self.hide()
      self.generateCollisionShapes(recursive: true)
      
   }
   
   required init?(coder: NSCoder) {
      fatalError("Not implemented")
   }
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   private func convertToInteger(value: Float) -> String {
      let integer = Int(value)
      return "\(integer)"
   }
   
   private func getApexName(name: String, round: Int) -> String {
      return "\(name) - R\(round)"
   }
   
   private func getApexHeightAsString(_ height: Float) -> String {
      return "\(height.roundToDecimal(2))"
   }
   
   private func getApexSpeedAsString(_ speed: Float) -> String {
      return "\(speed.roundToDecimal(2))"
   }
   
   func setEntityName() {
      let round = self.viewModel.roundNum
      let playerId = self.viewModel.playerViewModel.playerId
      self.entityName = "\(round)_\(playerId)"
   }
   
   private func createCard() {
      playerDetailsPlain = qModelEntity(mesh: qMeshResource.generateBox(width: 0.32 * constants.golfCardSizeMultiplier, height: 0.037*constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.4))])
      apexRootEntity = qModelEntity(mesh: qMeshResource.generateBox(width: 0.31 * constants.golfCardSizeMultiplier, height: 0.036*constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.8))])
      playerDetailsPlain.addChild(apexRootEntity)
      apexRootEntity.setPosition(qVector3(0,0,0.001), relativeTo: playerDetailsPlain)
      
      let underLine = qModelEntity(mesh: qMeshResource.generateBox(width: 0.31 * constants.golfCardSizeMultiplier, height: 0.003*constants.golfCardSizeMultiplier,depth: 0), materials: [qUnlitMaterial(color: viewModel.playerViewModel.primaryColor)])
      apexRootEntity.addChild(underLine)
      underLine.setPosition(qVector3(0,-0.014*constants.golfCardSizeMultiplier,0.001), relativeTo: apexRootEntity)
      
      let apexFont = (UIFont (name: viewModel.apexCardDetailsFont, size: viewModel.apexCardDetailsFontSize * CGFloat(constants.golfCardSizeMultiplier)) ?? .systemFont(ofSize: 0.01 * CGFloat(constants.golfCardSizeMultiplier), weight: .semibold))
      let playerNameText = qMeshResource.generateText(getApexName(name: viewModel.playerViewModel.name, round: viewModel.roundNum), extrusionDepth: 0.002, font: apexFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      let nameTextEntity = qModelEntity(mesh: playerNameText, materials: [qUnlitMaterial(color:.white)])
      apexRootEntity.addChild(nameTextEntity)
      let xExtentForNameTextEntity = apexRootEntity.model!.mesh.bounds.min.x+0.007 * constants.golfCardSizeMultiplier+(nameTextEntity.model?.mesh.bounds.extents.x ?? 0)/2
      nameTextEntity.setPositionForText( SIMD3<Float> (Float(xExtentForNameTextEntity), 0.05, 0.00001), relativeTo: apexRootEntity, withFont: apexFont)
      
      let apexvalue = qMeshResource.generateText(convertToInteger(value: viewModel.apexHeight), extrusionDepth: 0.002, font: apexFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      apexValueEntity = qModelEntity(mesh: apexvalue, materials: [qUnlitMaterial(color:.white)])
      apexRootEntity.addChild(apexValueEntity)
      apexValueEntity.setPositionForText( SIMD3<Float> (Float(0.045 * constants.golfCardSizeMultiplier), 0.05, 0.00001), relativeTo: apexRootEntity, withFont: apexFont)

      let unitFont = (UIFont (name: viewModel.apexCardUnitFont, size: viewModel.apexCardUnitFontSize * CGFloat(constants.golfCardSizeMultiplier)) ?? .systemFont(ofSize: 0.01*CGFloat(constants.golfCardSizeMultiplier), weight: .semibold))
      let apexValueFt = qMeshResource.generateText("Ft", extrusionDepth: 0.002, font: unitFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      apexValueFtEntity = qModelEntity(mesh: apexValueFt, materials: [qUnlitMaterial(color:.white)])
      apexRootEntity.addChild(apexValueFtEntity)
      let xExtentForApexUnitEntity = 0.047 * constants.golfCardSizeMultiplier+apexValueEntity.model!.mesh.bounds.extents.x/2+0.2+(apexValueFtEntity.model?.mesh.bounds.extents.x ?? 0)/2
      apexValueFtEntity.setPositionForText( SIMD3<Float> (Float(xExtentForApexUnitEntity), 0.00, 0.00001), relativeTo: apexRootEntity, withFont: unitFont)
      
      let speedValue = qMeshResource.generateText(convertToInteger(value: viewModel.ballSpeed), extrusionDepth: 0.002, font: apexFont , containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      speedvalueEntity = qModelEntity(mesh: speedValue, materials: [qUnlitMaterial(color:.white)])
      apexRootEntity.addChild(speedvalueEntity)
      
      let speedValueFt = qMeshResource.generateText("Mph", extrusionDepth: 0.002, font: unitFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      speedValueFtEntity = qModelEntity(mesh: speedValueFt, materials: [qUnlitMaterial(color:.white)])
      apexRootEntity.addChild(speedValueFtEntity)
      let xExtentForSpeedEntity = 3.6007963 + (speedvalueEntity.model?.mesh.bounds.extents.x ?? 0)/2
      speedvalueEntity.setPositionForText( SIMD3<Float> (xExtentForSpeedEntity,0.05,0.00001), relativeTo: apexRootEntity, withFont: apexFont)
      let xExtentForSpeedUnitEntity = xExtentForSpeedEntity + speedvalueEntity.model!.mesh.bounds.extents.x/2 + 0.2 + (speedValueFtEntity.model?.mesh.bounds.extents.x ?? 0)/2
      speedValueFtEntity.setPositionForText( SIMD3<Float> (Float(xExtentForSpeedUnitEntity), -0.02, 0.00001), relativeTo: apexRootEntity, withFont: unitFont)
      cardRootEntity.addChild(playerDetailsPlain)
      self.addChild(cardRootEntity)
      self.forceName(self.entityName, recursive: true)
   }
   
   func update(height:Float,speed:Float) {
      let apexFont = (UIFont (name: viewModel.apexCardDetailsFont, size: viewModel.apexCardDetailsFontSize * CGFloat(constants.golfCardSizeMultiplier)) ?? .systemFont(ofSize: 0.01 * CGFloat(constants.golfCardSizeMultiplier), weight: .semibold))
      let unitFont = (UIFont (name: viewModel.apexCardUnitFont, size: viewModel.apexCardUnitFontSize * CGFloat(constants.golfCardSizeMultiplier)) ?? .systemFont(ofSize: 0.01 * CGFloat(constants.golfCardSizeMultiplier), weight: .semibold))
      apexValueEntity.model?.mesh = .generateText(convertToInteger(value: height), extrusionDepth: 0.002, font: apexFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      apexValueEntity.setPositionForText( SIMD3<Float> (Float(0.045 * constants.golfCardSizeMultiplier), 0.05, 0.00001), relativeTo: apexValueEntity.parent, withFont: apexFont)
      let xExtentForApexUnitEntity = 0.047*constants.golfCardSizeMultiplier+apexValueEntity.model!.mesh.bounds.extents.x/2+0.2+(apexValueFtEntity.model?.mesh.bounds.extents.x ?? 0)/2
      apexValueFtEntity.setPositionForText( SIMD3<Float> (Float(xExtentForApexUnitEntity), 0.00, 0.00001), relativeTo: apexRootEntity, withFont: unitFont)
      speedvalueEntity.model?.mesh = .generateText(convertToInteger(value: speed), extrusionDepth: 0.002, font: apexFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      let xExtentForSpeedEntity = 3.6007963 + (speedvalueEntity.model?.mesh.bounds.extents.x ?? 0)/2
      speedvalueEntity.setPositionForText( SIMD3<Float> (xExtentForSpeedEntity,0.05,0.00001), relativeTo: apexRootEntity, withFont: apexFont)
      let xExtentForSpeedUnitEntity = xExtentForSpeedEntity + speedvalueEntity.model!.mesh.bounds.extents.x/2 + 0.2 + (speedValueFtEntity.model?.mesh.bounds.extents.x ?? 0)/2
      speedValueFtEntity.setPositionForText( SIMD3<Float> (Float(xExtentForSpeedUnitEntity), -0.02, 0.00001), relativeTo: apexRootEntity, withFont: unitFont)
   }
}
