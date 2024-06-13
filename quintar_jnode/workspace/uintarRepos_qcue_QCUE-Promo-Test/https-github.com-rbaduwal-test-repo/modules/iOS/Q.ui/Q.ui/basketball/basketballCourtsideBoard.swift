import simd

internal class basketballCourtsideBoard : qEntity, qHasModel, qHasCollision {

   public enum LOCATION {
      case COURTSIDE
      case USER
      case UNKNOWN
   }
   public private(set) var location: LOCATION = .UNKNOWN
   public var distanceFromFloor: Float = defaults.courtsideBoardDistanceFromFloor
   public var distanceFromCamera: Float = defaults.courtsideBoardDistanceFromCamera
   public var animationSpeed: Double = defaults.courtsideBoardAnimationSpeed
   
   public func animate(to location: LOCATION,
      withUserPosition userPos: SIMD3<Double>) {
      
      // Requirements to continue:
      //  - location is different than what we already have
      //  - we have dimensions
      //  - we have a valid view direction
      if self.location == location { return }
      guard let unscaledBoardHeight: Float = self.model?.mesh.bounds.extents.y else { return }
      let boardHeight = self.scale.y * unscaledBoardHeight
      if userPos == SIMD3<Double>.zero { return }
      
      var targetTransform = qTransform()
      
      // Don't mess with the scale (ideally this will be all 1's though)
      targetTransform.scale = self.transform.scale
      
      // Are we targeting courtside or the user?
      switch location {
         case .COURTSIDE:
            // If courtside, then we need to know which quadrant the user is in
            let quadrant = basketballVenue.getQuadrant(userPosition: userPos)
            switch quadrant {
               case ._0:
                  targetTransform.translation = SIMD3<Float>(-Float(defaults.courtHalfLength), 0, distanceFromFloor + boardHeight / 2)
                  targetTransform.rotation = simd_mul(simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0)), simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0)))
               case ._90:
                  targetTransform.translation = SIMD3<Float>(0, -Float(defaults.courtHalfWidth), distanceFromFloor + boardHeight / 2)
                  targetTransform.rotation = simd_mul(simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0)), simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0)))
               case ._180:
                  targetTransform.translation = SIMD3<Float>(Float(defaults.courtHalfLength), 0, distanceFromFloor + boardHeight / 2)
                  targetTransform.rotation = simd_mul(simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0)), simd_quatf(angle: -.pi/2, axis: SIMD3<Float>(0, 1, 0)))
               case ._270:
                  targetTransform.translation = SIMD3<Float>(0, Float(defaults.courtHalfLength), distanceFromFloor + boardHeight / 2)
                  targetTransform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0))
               default: return
              
            }
         case .USER:
            // If user, then we need to know where the user is
            
            // Get the unit direction vector from the user's location to center court
            let viewDirection = simd_normalize(SIMD3<Float>(-userPos))
            
            // Place the board in front of the user some distance along the view-direction axis, where the bottom of the element is on top of the vector
            let positionAlongViewDirection = SIMD3<Float>(userPos) + (viewDirection * distanceFromCamera) + SIMD3<Float>(0, 0, boardHeight / 2)
            targetTransform.translation = positionAlongViewDirection
            
            // Rotate upright
            targetTransform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0))
            
            // Rotation so that we look at the user, but without any yaw.
            // TODO: We can add yaw later if need be
            // I'd love to tell you why we need an extra pi/2, but I don't know why :)
            let xyRotation = atan2(userPos.y, userPos.x) + .pi/2.0
            targetTransform.rotation *= simd_quatf(angle: Float(xyRotation), axis: SIMD3<Float>(0, 1, 0))
         case .UNKNOWN:
            targetTransform = self.transform
      }
      
      // Suddenly appear if this is the first time OR we are disabled (to avoid animations being automatically queued by RealityKit).
      // Otherwise smoothly animate
      if self.location == .UNKNOWN || !self.isEnabled {
         self.transform = targetTransform
      } else {
         self.move(to: targetTransform, relativeTo: self.parent, duration: self.animationSpeed)
      }
      
      // Update our current location
      self.location = location
   }
}
