import simd

internal extension simd_float4x4 {
   init(_ values: [Double]) {
      self.init([
         simd_float4(Float(values[0]), Float(values[1]), Float(values[2]), Float(values[3])),
         simd_float4(Float(values[4]), Float(values[5]), Float(values[6]), Float(values[7])),
         simd_float4(Float(values[8]), Float(values[9]), Float(values[10]), Float(values[11])),
         simd_float4(Float(values[12]), Float(values[13]), Float(values[14]), Float(values[15])),
      ])
   }
   func multiply(matrix: simd_float4x4) -> simd_float4x4 {
      return simd_mul(self, matrix)
   }
   mutating func translate(_ vector: SIMD3<Float>) {
      self.columns.3.x += vector.x
      self.columns.3.y += vector.y
      self.columns.3.z += vector.z
   }
   mutating func rotate(_ quat: simd_quatf) {
      self *= simd_float4x4(quat)
   }
   func invert() -> simd_float4x4 {
      return self.inverse
   }
}

internal extension SIMD3 where Scalar == Float {
   
   var normalized: SIMD3<Float> {
      return self / self.length
   }
   var length: Float {
      return sqrt(length_squared(self))
   }
   static func createIntermediatePoints(startPoint: SIMD3<Float>,
      endPoint: SIMD3<Float>,
      numIntermediatePoints: Int) -> [SIMD3<Float>] {
      var points:[SIMD3<Float>] = []
      let vector = endPoint - startPoint
      let length = simd.length(vector)
      let normalizedVector = vector.normalized
      
      for index in 1..<numIntermediatePoints {
         let intermediateLength = length * (Float(index)/Float(numIntermediatePoints))
         let intermediateVector = startPoint + SIMD3<Float>(intermediateLength * normalizedVector.x, intermediateLength * normalizedVector.y, intermediateLength * normalizedVector.z)
         points.append(intermediateVector)
      }
      return points
   }
   func rotationTo(_ to: SIMD3<Float>) -> simd_quatf {
      return simd_quaternion(self, to)
   }
   func distanceTo(_ to: SIMD3<Float>) -> Float {
      return distance(self, to)
   }
}

internal extension simd_quatf {
   func split(by factor: Float = 2) -> simd_quatf {
      if self.angle == 0 {
         return self
      } else {
         return simd_quatf(angle: self.angle / factor, axis: self.axis)
      }
   }
   static func zero() -> simd_quatf {
      return simd_quatf(angle: 0, axis: [1, 0, 0])
   }
}

