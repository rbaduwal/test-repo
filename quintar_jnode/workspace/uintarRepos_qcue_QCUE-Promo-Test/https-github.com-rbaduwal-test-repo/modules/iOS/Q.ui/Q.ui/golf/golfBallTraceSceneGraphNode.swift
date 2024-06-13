import Foundation
import SceneKit
import Q

class golfBallTraceSceneGraphNode: qEntity, qHasModel {
   
   public var hasFade: Bool  = false
   public var isDotted: Bool  = false
   public var greenPlayerCard: golfGreenPlayerCard? = nil
   public var isAnimating: Bool = false
   public var animationSpeed: Float = defaults.flightAnimationSpeed
   
   // Ball trace event
   public var ballTraceAnimationProgress: ((Q.golfPlayer, String, Int, qVector3)->())? = nil
   
   private var playerId: Int = 0
   private var player: golfPlayer
   private var shotID: String = ""
   private var isFromGreenContainer: Bool = false
   private var animationTimer:Timer? = nil {
      willSet {
         animationTimer?.invalidate()
      }
   }
   private var pathList = [qVector3]()
   private var radius: Float = 0.0
   private var traceColor: UIColor = .red
   private var vectorsAddedToTrace = 0
   private var startFadeout: Bool = false
   private var traceOpacity: CGFloat = 0
   private var opacityCount = 1
   private var fadeInOpacityCount = 1
   private var isPuttTrace: Bool = false
   private var apexNode: golfApexCard? = nil
   private var apexPoint: qVector3? = nil
   private var lastTraceNode: lineSceneGraphNode?
   
   //private var points:[simd_float3]
   private var material: qMaterial?
   private var sides: Int = 18
   private var indices: [UInt32] = []
   private var mesh: qMeshResource?
   private var traceModel: qEntity?
   private var positions = [simd_float3]()
   
   init(player: golfPlayer, shotID:String, isFromGreenContainer: Bool) {
      self.shotID = shotID
      self.player = player
      
      super.init()
      self.isFromGreenContainer = isFromGreenContainer
   }
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   required init() {
      fatalError("init() has not been implemented")
   }

   public func setApex( apexNode: golfApexCard?, apexPoint: qVector3? ) {
      self.apexNode = apexNode
      self.apexPoint = apexPoint
   }
   public func getPoint(index: Int) -> qVector3? {
      if index < pathList.count {
         return pathList[index]
      }
      return nil
   }
   public func create(radius: Float, vectors: [qVector3], ballTraceColor: UIColor, opacity: CGFloat, isPuttTrace: Bool) {
      self.isPuttTrace = isPuttTrace
      animationTimer = nil
      self.radius = radius
      self.traceOpacity = opacity
      pathList = vectors
      self.traceColor = ballTraceColor
      
      self.material = qUnlitMaterial(color: ballTraceColor.withAlphaComponent(opacity))
      //lastTraceNode = addNewBallTraceNode()
   }
   public func prepareToAnimate() {
      self.animationTimer?.invalidate()
      animationTimer = nil
      isAnimating = false
      self.startFadeout = false
      self.opacityCount = 1
      self.vectorsAddedToTrace = 0
      removeAll()
      self.isEnabled = true
      lastTraceNode = nil//addNewBallTraceNode(with: [])
      if isPuttTrace {
         animationSpeed = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().puttTraceAnimationSpeed ?? defaults.puttTraceAnimationSpeed
      }else{
         animationSpeed = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().flightAnimationSpeed ?? defaults.flightAnimationSpeed
      }
   }
   public func startAnimation(completion: @escaping()->()){
      isAnimating = true
      self.vectorsAddedToTrace = 0
      
      if self.isPuttTrace {
         if let startPosition = self.pathList.first {
            var ballNode: qEntity?
            if(!isFromGreenContainer) {
               ballNode = self.createBallForActualGreen(ballRadius: CGFloat(ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().ballSize ?? defaults.ballSize), color: traceColor)
               ballNode?.position = qVector3(startPosition)
            } else {
               ballNode = self.createBallForGreenModel(
                  ballRadius: CGFloat(ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().ballSizeInModel ?? defaults.ballSizeInModel),
                  color: traceColor,
                  startPosition: startPosition)
            }
            if let golfBallNode = ballNode {
               self.addChild(golfBallNode)
            }
         }
      }
      
      animationTimer = Timer.scheduledTimer(withTimeInterval: Double(animationSpeed), repeats: true, block: { [weak self](timer) in
         guard let self = self else{return}
         DispatchQueue.main.async {
            
            if self.vectorsAddedToTrace+1 < self.pathList.count, !self.pathList.isEmpty{
               let startPoint = self.pathList[self.vectorsAddedToTrace]
               let endPoint = self.pathList[self.vectorsAddedToTrace + 1]
               let fadeInEndIndex = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeinEndIndex ?? defaults.fadeinEndIndex
               let fadeOutStartIndex = (ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeoutBallTraceStartIndex ?? defaults.fadeoutBallTraceStartIndex)
               let isInUnfadedPart = (self.vectorsAddedToTrace + 1 > fadeInEndIndex) && (self.pathList.count - self.vectorsAddedToTrace + 1) > fadeOutStartIndex
               if self.lastTraceNode != nil && !self.isDotted && (isInUnfadedPart || self.isPuttTrace) {
                  self.lastTraceNode?.add(wayPoint: endPoint)
               } else {
                  self.lastTraceNode = self.addNewBallTraceNode(with: [startPoint, endPoint])
               }
               
               if let callback = self.ballTraceAnimationProgress {
                  callback(self.player, self.shotID, self.vectorsAddedToTrace, startPoint)
               }
               
               // Show the apex card at the apex point
               if let apexNode = self.apexNode, let apexPoint = self.apexPoint {
                  if endPoint.x == apexPoint.x && endPoint.y == apexPoint.y && endPoint.z == apexPoint.z {
                     apexNode.show()
                  }
               }
               
               if (self.pathList.count - self.vectorsAddedToTrace) == (ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeoutBallTraceStartIndex ?? defaults.fadeoutBallTraceStartIndex) && self.isPuttTrace == false{
                  self.startFadeout = true
               }
               
               if self.isDotted {
                  self.vectorsAddedToTrace += 2
               } else {
                  self.vectorsAddedToTrace += 1
               }
               
               if self.isPuttTrace {
                  self.greenPlayerCard?.viewModel.ballLiePosition = endPoint
               }
            } else {
               self.isAnimating = false
               self.animationTimer = nil
               
               if !self.hasFade {
                  if !self.isFromGreenContainer {
                     NotificationCenter.default.post(name: .ballTraceAnimationDidCompleteNotification, object: nil, userInfo: ["player": self.player,"shotID":self.shotID])
                  } else {
                     NotificationCenter.default.post(name: .ballTraceAnimationOnGreenDidCompleteNotification, object: nil, userInfo: ["player": self.player,"shotID":self.shotID])
                  }
               } else {
                  if !self.isFromGreenContainer {
                     NotificationCenter.default.post(name: .ballTraceAnimationDidCompleteNotification, object: nil, userInfo: ["player": self.player,"shotID":self.shotID,"ballTrace":self.pathList])
                  } else {
                     NotificationCenter.default.post(name: .ballTraceAnimationOnGreenDidCompleteNotification, object: nil, userInfo: ["player": self.player,"shotID":self.shotID,"ballTrace":self.pathList])
                  }
               }
               completion()
            }
         }
      })
   }
   public func releaseResources() {
      self.children.removeAll()
      animationTimer = nil
   }
   
   private func lerp(min: Float, max: Float, weight: Float)->Float{
      return min + (max - min ) * weight
   }
   private func removeAll(){
      self.children.removeAll()
   }
   private func createBallForGreenModel(ballRadius: CGFloat, color: UIColor, startPosition: qVector3) -> qEntity{
      let ball = qModelEntity( mesh: .generateSphere(radius: Float(ballRadius)), materials: [qUnlitMaterial(color: color)])
      ball.position = startPosition
      return ball
   }
   private func createBallForActualGreen(ballRadius: CGFloat, color: UIColor) -> qEntity {
      let ball = qModelEntity( mesh: .generateSphere(radius: Float(ballRadius)), materials: [qUnlitMaterial(color: color)])
      return ball
   }
   private func addNewBallTraceNode(with vectors: [qVector3] = []) -> lineSceneGraphNode {
      var opacity: CGFloat = 1
      var newBallTrackNode: lineSceneGraphNode!
      
      var material = qUnlitMaterial()
      //        material.faceCulling = .none
      //        //material.emissiveColor = .init(color: color)
      //        material.roughness = .init(floatLiteral: 1)
      //        material.metallic = .init(floatLiteral: 0)
      
      let pointsForOpacityFadeIn = (ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeinEndIndex ?? defaults.fadeinEndIndex) - (ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeinStartIndex ?? defaults.fadeinStartIndex)
      if hasFade == true && isPuttTrace == false {
         if fadeInOpacityCount >= pointsForOpacityFadeIn {
            opacity = CGFloat(1)
         } else {
            let opacityValue = lerp(min: Float(self.traceOpacity), max: 0, weight: (Float(pointsForOpacityFadeIn) - Float(fadeInOpacityCount))/Float(pointsForOpacityFadeIn))
            opacity = CGFloat(opacityValue)
         }
         fadeInOpacityCount = fadeInOpacityCount + 1
         if startFadeout == true {
            let pointsForOpacity = (ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeoutBallTraceStartIndex ?? defaults.fadeoutBallTraceStartIndex) - (ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().fadeoutBallTraceEndIndex ?? defaults.fadeoutBallTraceEndIndex)
            if opacityCount >= pointsForOpacity {
               opacity = CGFloat(0)
            }else{
               let opacityValue = lerp(min: 0.0, max: Float(self.traceOpacity), weight: (Float(pointsForOpacity) - Float(opacityCount))/Float(pointsForOpacity))
               opacity = CGFloat(opacityValue)
            }
            opacityCount = opacityCount+1
         }
         material.color = .init(tint: traceColor.withAlphaComponent(opacity))
      } else {
         material.color = .init(tint: traceColor.withAlphaComponent(self.traceOpacity))
      }
      
      newBallTrackNode  = lineSceneGraphNode(
         with: vectors,
         radius: radius,
         edges: 12,
         maxTurning: 12,
         material: material
      )
      self.addChild(newBallTrackNode!)
      
      return newBallTrackNode
   }
   private func rotationBetween2Vectors(start: simd_float3, end: simd_float3) -> simd_quatf {
      return simd_quaternion(start, end)
   }
}
