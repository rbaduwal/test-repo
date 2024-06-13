import SceneKit

internal extension SCNVector3 {
   static var zero: SCNVector3 { return SCNVector3Zero }
}

internal extension SCNQuaternion {
   init(angle: Float, axis: SIMD3<Float>) {
      let simdQuatf = simd_quatf(angle: angle, axis: axis)
      self.init(simdQuatf.vector.x, simdQuatf.vector.y, simdQuatf.vector.z, simdQuatf.vector.w)
   }
}
