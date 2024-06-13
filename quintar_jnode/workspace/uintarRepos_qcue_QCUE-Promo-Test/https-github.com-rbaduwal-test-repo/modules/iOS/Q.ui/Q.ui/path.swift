import simd
import Q

public class path: qEntity, qHasModel {
   public private(set) var length: Float = 0
   public private(set) var waypoints: [SIMD3<Float>] {
      didSet {
         self.update()
      }
   }
   public var radius: Float {
      didSet {
         self.update()
      }
   }
   public var edges: Int {
      didSet {
         self.update()
      }
   }
   public var maxTurning: Int {
      didSet {
         self.update()
      }
   }
   
   // JSON parsing
   public struct pathDecodable: Decodable {
      let Radius: Float
      let Segments: [[PointDecodable]]
      struct PointDecodable: Decodable {
         let X: Float
         let Y: Float
         let Z: Float
      }
   }
   
   private var material: qMaterial!
   
   public init(with waypoints: [SIMD3<Float>] = [],
      radius: Float = defaults.shotRadius,
      edges: Int = defaults.shotNumEdges,
      maxTurning: Int = 4,
      material: qMaterial) {
      self.waypoints = waypoints
      self.radius = radius
      self.edges = edges
      self.maxTurning = maxTurning
      self.material = material
      super.init()
      update()
   }
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   public override required init() {
      fatalError("init() has not been implemented")
   }
   
   public func add(waypoint: SIMD3<Float>) {
      // TODO: optimise this function to not recalculate all points
      self.add(waypoints: [waypoint])
   }
   public func add(waypoints: [SIMD3<Float>]) {
      // TODO: optimise this function to not recalculate all points
      self.waypoints.append(contentsOf: waypoints)
   }
   
   private func update() {
      
      self.model = nil
      self.length = 0
      
      if !waypoints.isEmpty {
         let (mesh, length) = self.createMesh( with: self.waypoints,
            radius: self.radius,
            edges: self.edges,
            maxTurning: self.maxTurning )
         
         if let m = mesh {
            self.model = qModelComponent(mesh: m, materials: [self.material])
            self.length = length
         }
      }
   }
   private func createMesh(with waypoints: [SIMD3<Float>],
      radius: Float,
      edges: Int,
      maxTurning: Int) -> (qMeshResource?, Float) {
      
      if waypoints.count < 2 {
         return (nil, 0)
      }
      guard var lastLocation = waypoints.first else {
         return (nil, 0)
      }
      
      var trueNormals = [SIMD3<Float>]()
      var trueUVMap = [SIMD2<Float>]()
      var trueVs = [SIMD3<Float>]()
      var trueInds = [UInt32]()
      
      var lastforward = SIMD3<Float>(0, 1, 0)
      var cPoints = generateCircularPoints(radius: radius, edges: edges)
      let textureXs = cPoints.enumerated().map { (val) -> Float in
         return Float(val.offset) / Float(edges - 1)
      }
     
      var lineLength: Float = 0
      for (index, point) in waypoints.enumerated() {
         let newRotation: simd_quatf
         if index == 0 {
            let startDirection = (waypoints[index + 1] - point).normalized
            cPoints = generateCircularPoints(
               radius: radius,
               edges: edges,
               orientation: lastforward.rotationTo(startDirection)
            )
            lastforward = startDirection.normalized
            newRotation = simd_quatf.zero()
         } else if index < waypoints.count - 1 {
            trueVs.append(contentsOf: Array(trueVs[(trueVs.count - edges * 2)...]))
            trueUVMap.append(contentsOf: Array(trueUVMap[(trueUVMap.count - edges * 2)...]))
            trueNormals.append(contentsOf: cPoints.map({$0.normalized}))
            
            newRotation = lastforward.rotationTo((waypoints[index + 1] - waypoints[index]).normalized)
         } else {
            //                cPoints = cPoints.map { lastPartRotation.normalized.act($0) }
            newRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0))
         }
         
         if index > 0 {
            let halfRotation = newRotation.split(by: 2)
            if (point.distanceTo(waypoints[index - 1]) > radius * 2) {
               let mTurn = max(1, min(newRotation.angle / .pi, 1) * Float(maxTurning))
               
               if mTurn > 1 {
                  let partRotation = newRotation.split(by: Float(mTurn))
                  let halfForward = newRotation.split(by: 2).act(lastforward)
                  
                  for i in 0..<Int(mTurn) {
                     trueNormals.append(contentsOf: cPoints.map { ($0.normalized) })
                     let angleProgress = Float(i) / Float(mTurn - 1) - 0.5
                     let tangle = radius * angleProgress
                     let nextLocation = point + (halfForward.normalized * tangle)
                     lineLength += lastLocation.distanceTo(nextLocation)
                     lastLocation = nextLocation
                     trueVs.append(contentsOf: cPoints.map { ($0 + nextLocation) })
                     trueUVMap.append(contentsOf: textureXs.map { SIMD2([Float($0), Float(lineLength)]) })
                     addCylinderVertices(to: &trueInds, startingAt: trueVs.count - edges * 4, edges: edges)
                     cPoints = cPoints.map { partRotation.normalized.act($0) }
                     lastforward = partRotation.normalized.act(lastforward)
                  }
                  continue
               }
            }
            // fallback and just apply the half rotation for the turn
            cPoints = cPoints.map { halfRotation.normalized.act($0) }
            lastforward = halfRotation.normalized.act(lastforward)
            
            trueNormals.append(contentsOf: cPoints.map { ($0.normalized) })
            trueVs.append(contentsOf: cPoints.map { ($0 + point) })
            lineLength += lastLocation.distanceTo(point)
            lastLocation = point
            trueUVMap.append(contentsOf: textureXs.map { SIMD2([Float($0), Float(lineLength)]) })
            addCylinderVertices(to: &trueInds, startingAt: trueVs.count - edges * 4, edges: edges)
            cPoints = cPoints.map { halfRotation.normalized.act($0) }
            lastforward = halfRotation.normalized.act(lastforward)
            //                lastPartRotation = halfRotation
         } else {
            cPoints = cPoints.map { newRotation.act($0) }
            lastforward = newRotation.act(lastforward)
            
            trueNormals.append(contentsOf: cPoints.map { ($0.normalized) })
            trueUVMap.append(contentsOf: textureXs.map { SIMD2([Float($0), Float(lineLength)]) })
            trueVs.append(contentsOf: cPoints.map { ($0 + point) })
            
         }
      }
      
      return (qMeshResource.generate( triangleVertices: trueVs,
         indices: trueInds,
         normals: trueNormals,
         uvs: trueUVMap ), lineLength)
   }
   private func generateCircularPoints( radius: Float,
      edges: Int,
      orientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0)) ) -> [SIMD3<Float>] {
      var angle: Float = 0
      var verts = [SIMD3<Float>]()
      let angleAdd = Float.pi * 2 / Float(edges)
      for index in 0..<edges {
         let vert = SIMD3<Float>(radius * cos(angle), 0, radius * sin(angle))
         angle += angleAdd
         verts.append(orientation.act(vert))
         if index > 0 {
            verts.append(verts.last!)
         }
      }
      verts.append(verts.first!)
      return verts
   }
   private func addCylinderVertices( to array: inout [UInt32], startingAt: Int, edges: Int ) {
      for i in 0..<edges {
         let fourI = 2 * i + startingAt
         let rv = Int(edges * 2)
         array.append(UInt32(1 + fourI + rv))
         array.append(UInt32(1 + fourI))
         array.append(UInt32(0 + fourI))
         array.append(UInt32(0 + fourI))
         array.append(UInt32(0 + fourI + rv))
         array.append(UInt32(1 + fourI + rv))
      }
   }
}
