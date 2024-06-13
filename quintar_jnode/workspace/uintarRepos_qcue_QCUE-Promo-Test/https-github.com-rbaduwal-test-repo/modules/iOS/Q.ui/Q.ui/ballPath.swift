import UIKit
import simd
import Q

internal class ballPath: qEntity, qHasModel {
   
   public private(set) var viewModel: ballPathViewModel
   public var isAnimating: Bool = false
   public var animationSpeed: Float = defaults.flightAnimationSpeed
   
   internal var animationTimer: Timer? = nil {
      willSet {
         animationTimer?.invalidate()
      }
   }
   internal var currentSegmentIndex = 0
   internal var lastTraceNode: path?
   //internal var material: qMaterial?
   
   init(viewModel: ballPathViewModel) {
      self.viewModel = viewModel
      
      super.init()
   }
   override required init() {
      fatalError("init() has not been implemented")
   }   
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   public func prepareToAnimate() {
      self.animationTimer?.invalidate()
      animationTimer = nil
      isAnimating = false
      self.currentSegmentIndex = 0
      removeAll()
      self.isEnabled = true
      lastTraceNode = nil//addNewBallTraceNode(with: [])
   }
   public func startAnimation(completion: @escaping()->()) {
      isAnimating = true
      
      animationTimer = Timer.scheduledTimer(withTimeInterval: Double(animationSpeed), repeats: true, block: { [weak self](timer) in
         guard let self = self else{return}
         DispatchQueue.main.async {
            
            if self.currentSegmentIndex + 1 < self.viewModel.waypoints.count, !self.viewModel.waypoints.isEmpty {
               let startPoint = self.viewModel.waypoints[self.currentSegmentIndex]
               let endPoint = self.viewModel.waypoints[self.currentSegmentIndex + 1]
               self.lastTraceNode = self.addNewBallTraceNode(with: [startPoint, endPoint])
               self.currentSegmentIndex += 1
            } else {
               self.isAnimating = false
               self.animationTimer = nil
               
               completion()
            }
         }
      })
   }
   public func releaseResources() {
      self.removeAllChildren()
      animationTimer = nil
   }
   public func pauseAnimation() {
       // Override this function to pause animation.
   }
   public func resumeAnimation() {
       // Override this function to resume animation.
   }
   
//   internal func update() {
//      animationTimer = nil
//      self.material = UnlitMaterial(color: self.viewModel.color.withAlphaComponent(CGFloat(self.viewModel.opacity)))
//   }
   internal func lerp(min: Float, max: Float, weight: Float)->Float{
      return min + (max - min ) * weight
   }
   internal func removeAll(){
      self.removeAllChildren()
   }
   
   internal func addNewBallTraceNode(with waypoints: [SIMD3<Float>] = []) -> path {
      let newBallTrackNode = path( with: waypoints,
         radius: self.viewModel.radius,
         edges: self.viewModel.numEdges,
         maxTurning: self.viewModel.maxNumTurns,
         material: self.createSegmentMaterial() )
      self.addChild(newBallTrackNode)
      
      return newBallTrackNode
   }
   internal func createSegmentMaterial() -> qMaterial {
      var segmentOpacity = min(self.viewModel.opacity, 1.0)
      
      // Set the opacity for the fade in/out
      if self.viewModel.fadeInPercentage > 0.0 {
         let fadeInEndIndex = Int(self.viewModel.fadeInPercentage * Float(self.viewModel.waypoints.count))
         let opacityOffset = 0.5/Float(fadeInEndIndex)
         segmentOpacity *= min(Float(self.currentSegmentIndex)/Float(fadeInEndIndex) + opacityOffset, 1.0)
      }
      if self.viewModel.fadeOutPercentage > 0.0 {
         let fadeOutStartIndexReverse = Int(self.viewModel.fadeOutPercentage * Float(self.viewModel.waypoints.count))
         let opacityOffset = 0.5/Float(fadeOutStartIndexReverse)
         segmentOpacity *= min(Float(self.viewModel.waypoints.count - self.currentSegmentIndex)/Float(fadeOutStartIndexReverse) + opacityOffset, 1.0)
      }
      var material = qUnlitMaterial()
      material.color = .init(tint: self.viewModel.color.withAlphaComponent(CGFloat(segmentOpacity)))
      
      return material
   }
}
