//import UIKit
//import simd
//import Q
//
//class outlineSceneGraphNode: qEntity, qHasModel{
//   
//   private var points: [qVector3]
//   private var material: qMaterial
//   private var radius: Float
//   private var sides: Int
//   private var indices: [UInt32] = []
//   private var mesh: qMeshResource?
//   private var currentModel: qEntity?
//   
//   convenience init(points: [qVector3]) {
//      self.init(color: .green, points: points, radius: 0.3, sides: 18)
//   }
//   
//   required init(color: UIColor, points: [qVector3], radius: Float, sides: Int) {
//      var material = qPhysicallyBasedMaterial()
//      material.baseColor = .init(tint: color, texture: nil)
//      material.emissiveColor = .init(color: color, texture: nil)
//      material.specular = .init(floatLiteral: 1)
//      material.roughness = .init(floatLiteral: 0.0)
//      material.metallic = .init(floatLiteral: 1)
//      
//      self.material = material
//      self.points = points
//      self.radius = radius
//      self.sides = sides
//      super.init()
//      generateOutline()
//   }
//   
//   required init(){
//      fatalError("init() has not been implemented")
//   }
//   required init?(coder aDecoder: NSCoder) {
//      fatalError("init(coder:) has not been implemented")
//   }
//   
//   func generateOutline(){
//      generateCircularMesh(with: points)
//   }
//   
//   func generateCircularMesh(with points:[qVector3]){
//      var positions = [qVector3]()
//      for (index,point) in points.enumerated(){
//         var circularPoints = [qVector3]()
//         if points.count > index + 1{
//            circularPoints = getCircularOffsetPointsNew(from: point, to: points[index+1], radius: radius, sides: sides)
//         }else{
//            circularPoints = getCircularOffsetPointsNew(from: point, to: points[index-1], radius: radius, sides: sides)
//         }
//         positions.append(contentsOf: circularPoints)
//      }
//      indices = getIndices(points: positions, for: sides)
//      var meshdescriptor = qMeshDescriptor()
//      meshdescriptor.positions = .init(positions)
//      meshdescriptor.primitives = .trianglesAndQuads(triangles: [], quads: indices)
//      do{
//         let meshResource = try qMeshResource.generate(from: [meshdescriptor])
//         self.mesh = meshResource
//         currentModel = qModelEntity(mesh: meshResource, materials: [self.material])
//         self.addChild(currentModel!)
//      }catch{
//         log.instance.push(.INFO, msg: "Mesh create fail : \(error) \(error.localizedDescription)")
//      }
//   }
//   
//   func getCircularOffsetPointsNew(from point: qVector3, to  nextPoint: qVector3?, radius: Float, sides: Int) -> [qVector3] {
//      var angle:Float = 0
//      var vertices:[qVector3] = []
//      let incrementAngle = 2 * Float.pi / Float(sides)
//      
//      if let nextPoint = nextPoint{
//         let orientation: simd_quatf = point.rotationTo(nextPoint).normalized
//         for _ in 0..<sides{
//            let vertex = qVector3(x: radius * cos(angle), y: 0, z: radius * sin(angle))
//            let rotatedVertex = orientation.act(vertex)
//            let translatedVertex = qVector3(x: point.x + rotatedVertex.x, y: point.y + rotatedVertex.y, z: point.z + rotatedVertex.z)
//            vertices.append(translatedVertex)
//            angle += incrementAngle
//         }
//      }else{
//         for _ in 0..<sides{
//            let vertex = qVector3(x: point.x + radius * cos(angle), y: point.y + radius * sin(angle) , z: point.z )
//            vertices.append(vertex)
//            angle += incrementAngle
//         }
//      }
//      return vertices
//   }
//   
//   func getIndices(points : [qVector3], for sides:Int) -> [UInt32]{
//      var indiceArray = [UInt32]()
//      for (index, _) in points.enumerated(){
//         var n:UInt32
//         var nNext:UInt32
//         var nDash:UInt32
//         var nNextDash:UInt32
//         
//         if (index + 1) % sides == 0{
//            n = UInt32(index)
//            nNext = UInt32(index - sides + 1)
//            nDash = n + UInt32(sides)
//            nNextDash = nNext + UInt32(sides) //  UInt32(index + sides + 2)
//         } else {
//            n = UInt32(index)
//            nNext = UInt32(index + 1)
//            nDash = UInt32(index + sides)
//            nNextDash = nDash + 1
//         }
//         
//         if nDash < points.count{
//            indiceArray.append(n)
//            indiceArray.append(nNext)
//            indiceArray.append(nNextDash)
//            indiceArray.append(nDash)
//            //indiceArray.append(n)
//         }
//      }
//      return indiceArray
//   }
//   
//   public func animateTo(percentage: Float) {
//      let start = 0
//      let end = Int(max(Float(indices.count) * percentage, 1))
//      if var contents = self.mesh?.contents{
//         contents.models = .init(contents.models.map({ model in
//            var newModel = model
//            newModel.parts = .init(model.parts.map({ part in
//               var newPart = part
//               newPart.triangleIndices = .init(self.indices[start...end])
//               return newPart
//            }))
//            return newModel
//         }))
//         try? self.mesh?.replace(with: contents)
//         self.replaceCurrentModel()
//      }
//   }
//   
//   private func replaceCurrentModel() {
//      guard mesh != nil, currentModel != nil else {
//         log.instance.push(.INFO, msg: "Cannot replace current model")
//         return
//      }
//      currentModel!.removeFromParent()
//      currentModel = qModelEntity(mesh: mesh!, materials: [self.material])
//      currentModel!.setPosition(qVector3(0, -0.15, -1), relativeTo: nil)
//      self.addChild(currentModel!)
//   }
//}
