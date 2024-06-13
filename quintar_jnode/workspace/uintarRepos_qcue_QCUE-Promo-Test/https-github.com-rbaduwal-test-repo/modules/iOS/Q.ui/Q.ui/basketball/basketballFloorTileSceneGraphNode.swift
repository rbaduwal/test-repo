import UIKit
import simd
import Q

internal class basketballFloorTileSceneGraphNode: qEntity, qHasModel {
   private var currentModel:qModelEntity?
   var rootFloorTileNode = qEntity()
   let meterToFeet:Float = 3.28
   
   required init(color: UIColor, scale: Float) {
      super.init()
      rootFloorTileNode.orientation = qQuaternion(angle:.pi/2, axis: SIMD3<Float>(1,0,0))  /* About x axis */
      rootFloorTileNode.scale = qVector3(meterToFeet,meterToFeet,meterToFeet)
      self.addChild(rootFloorTileNode)
      generateFloorTile(color: color, scale: scale)
      
   }
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   func generateFloorTile(color: UIColor, scale: Float) {
      // Positions of the vertices
      let positions: [qVector3] =  [
         qVector3(0.5,0,0),
         qVector3(0.25,0,-0.433),
         qVector3(-0.25,0,-0.433),
         qVector3(-0.5,0,0),
         qVector3(-0.25,0,0.433),
         qVector3(0.25,0,0.433),
         qVector3.zero]
      let mesh  = qMeshResource.generate( hexagonVertices: positions, indices: [0,1,2,3,4,5] )
      
      if let m = mesh {
         let triMat = qUnlitMaterial(color: color)
         self.currentModel = qModelEntity(mesh: m, materials: [triMat])
      }
      
      currentModel?.scale = qVector3(scale, scale, scale)
      if let model = currentModel {
         rootFloorTileNode.addChild(model)
      }
   }
}
