import UIKit
import simd
//import Combine

internal class basketballHeatMapSceneGraphNode: qEntity, qHasModel, qHasCollision {
   
   var heatMapArView: qARView?
   var rootHeatMapNode = qEntity()
   let meterToFeet:Float = 3.28
   //private var sceneEventsUpdateSubscription: Cancellable!
   var zoneEntity: qModelEntity?
   var textEntity: qModelEntity?
   var textRootEntity = qEntity()
   var isHomeSelected = false
   var courtAreaEntity = qEntity()
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   required init(heatMapArView: qARView) {
      self.heatMapArView = heatMapArView
      super.init()
      // rootHeatMapNode.orientation = simd_quatf(angle:.pi/2, axis: [1,0,0])  /* About x axis */
      rootHeatMapNode.scale = qVector3(meterToFeet,meterToFeet,meterToFeet)
      rootHeatMapNode.addChild(textRootEntity)
      self.addChild(rootHeatMapNode)
      setBillboardConstraints()
   }
   
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   func loadModel(name:String, scale:SIMD3<Float>) {
      zoneEntity = try? qEntity.loadModel(named: name)
      zoneEntity?.scale = qVector3(scale.x/meterToFeet,scale.y/meterToFeet,scale.z/meterToFeet)
      rootHeatMapNode.addChild(zoneEntity!)
   }
   func setZoneColor(color: UIColor) {
      let material = qUnlitMaterial(color: color)
      zoneEntity?.updateMaterials(materials: [material])
   }
   func createTextEntity(text: String, font: UIFont, color: UIColor, isSelectedHome: Bool, courtEntity: qEntity) -> qEntity {
      isHomeSelected = isSelectedHome
      courtAreaEntity = courtEntity
      textEntity?.removeFromParent()
      textEntity = qModelEntity(mesh: .generateText(text, extrusionDepth: 0.001, font: font, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: color)])
      if let textEntity = textEntity {
         textRootEntity.position = zoneEntity?.model?.mesh.bounds.center ?? qVector3(0,0,0)
         textRootEntity.orientation = qQuaternion(angle:.pi/2, axis: SIMD3<Float>(1,0,0))
         textRootEntity.addChild(textEntity)
         zoneEntity?.addChild(textRootEntity)
      }
      return textRootEntity
   }
   func setBillboardConstraints() {
//      sceneEventsUpdateSubscription = heatMapArView?.scene.subscribe(to: SceneEvents.Update.self) {[weak self] _ in
//         guard let self = self, let textEntity = self.textEntity else{return}
//         
//         if let arView = self.heatMapArView {
//            let cameraPosition = arView.cameraTransform.matrix.columns.3
//            let newPosition:SIMD3<Float> = [cameraPosition.x,0,cameraPosition.z]
//            textEntity.look(at: newPosition, from: textEntity.position(relativeTo: nil), upVector: [0,1,0], relativeTo: nil)
//            
//            var currentTransform = SCNMatrix4(textEntity.transform.matrix)
//            currentTransform = SCNMatrix4Rotate(currentTransform, Float.pi, 0, 1, 0)
//            textEntity.transform = Transform(matrix: simd_float4x4(currentTransform))
//         }
//      }
   }
}
