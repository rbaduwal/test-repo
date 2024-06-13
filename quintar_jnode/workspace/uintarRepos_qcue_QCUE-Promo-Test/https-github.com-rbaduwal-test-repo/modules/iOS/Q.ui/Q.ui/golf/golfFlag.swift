import UIKit
import simd
import Q

class golfFlag: qEntity, qHasModel {
   
   var flagEntity:qModelEntity = qModelEntity()
   var rootAREntity:qModelEntity = qModelEntity()
   var rootPGAEntity:qModelEntity = qModelEntity()
   var flagCenter:qVector3 = qVector3(0.0,0.0,0.0)
   let scaleFactor:Float = 5
   
   required override init() {
      super.init()
      self.loadFlag()
      rootPGAEntity.addChild(rootAREntity)
      let rotation = simd_quatf(angle: Float.pi/2, axis: SIMD3<Float>(1.0, 0.0, 0.0))
      self.rootPGAEntity.transform = qTransform(matrix: simd_float4x4(rotation))
      self.addChild(rootPGAEntity)
   }
   
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   func loadFlag() {
      let modelName = "Flag"
      let fileExtention = "usdz"
      
      do {
         let bundle = Bundle(identifier: constants.qUIBundleID)
         Bundle.main.path(forResource: modelName, ofType: fileExtention)
         guard let path = bundle?.path(forResource: modelName, ofType: fileExtention)else{
            return
         }
         let url = NSURL(fileURLWithPath: path)
        // let entity = try qEntity.load(contentsOf: url as URL)
         let entity = try qEntity.loadModel(contentsOf: url as URL)
         
         
         log.instance.push(.INFO, msg: entity.name ?? "")
         self.flagEntity.addChild(entity)
         let rotation = simd_quatf(angle: -Float.pi/2, axis: SIMD3<Float>(1.0, 0.0, 0.0))
         self.flagEntity.transform = qTransform(matrix: simd_float4x4(rotation))
         self.rootAREntity.addChild(flagEntity)
         self.flagEntity.scale = qVector3(scaleFactor,scaleFactor,scaleFactor)
      } catch {
         log.instance.push(.INFO, msg: "Failed to load flag")
      }
   }
   func show() {
      self.isEnabled = true
   }
   func hide() {
      self.isEnabled = false
   }
}
