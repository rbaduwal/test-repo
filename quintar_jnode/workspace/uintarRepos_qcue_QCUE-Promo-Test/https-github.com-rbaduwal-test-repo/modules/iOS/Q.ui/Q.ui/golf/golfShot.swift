import UIKit
import Q

internal class golfShot: ballPath {
   public var greenPlayerCard: golfGreenPlayerCard? = nil
   
   // Ball trace event
   public var ballTraceAnimationProgress: ((Q.golfPlayer, Int, Int, SIMD3<Float>)->())? = nil
   
   internal var apexNode: golfApexCard? = nil
   internal var apexNodes:golfApexCard? = nil
   internal var apexPoint: qVector3? = nil
   internal var isDotted: Bool  = false
   internal var isGroupReplay: Bool = false
   internal var hasFade: Bool = false // TODO: This should be deprecated, just use non-zero values of fade{In/Out}Percentage to indicate fades - see implementation already in ballPath
   
   private var isFromGreenContainer: Bool = false
   private var startFadeout: Bool = false
   
   init(viewModel: golfShotViewModel) {
      super.init(viewModel: viewModel)
   }
   required init() {
      fatalError("init() has not been implemented")
   }
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   public override func prepareToAnimate() {
      super.prepareToAnimate()
      
      startFadeout = false
      
      if let vm = self.viewModel as? golfShotViewModel {
         animationSpeed = vm.animationSpeed
      } else {
         animationSpeed = ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().flightAnimationSpeed ?? defaults.flightAnimationSpeed
      }
   }
   public override func startAnimation(completion: @escaping()->()){
      guard let vm = self.viewModel as? golfShotViewModel else { return }
      if vm.isPuttTrace {
         if let startPosition = vm.waypoints.first {
            var ballNode: qEntity?
            if(!isFromGreenContainer) {
               ballNode = self.createBallForActualGreen(ballRadius: CGFloat(ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().ballSize ?? defaults.ballSize), color: vm.color)
               ballNode?.position = qVector3(startPosition)
            } else {
               ballNode = self.createBallForGreenModel(
                  ballRadius: CGFloat(ObjectFactory.shared.sportsVenueController?.getBallTraceConfig().ballSizeInModel ?? defaults.ballSizeInModel),
                  color: vm.color,
                  startPosition: startPosition)
            }
            if let golfBallNode = ballNode {
               self.addChild(golfBallNode)
            }
         }
      }
      
      animationTimer = Timer.scheduledTimer(withTimeInterval: Double(animationSpeed), repeats: true, block: { [weak self](timer) in
         guard let self = self else{return}
         guard let vm = self.viewModel as? golfShotViewModel else { return }
         DispatchQueue.main.async {
            
            if self.currentSegmentIndex+1 < vm.waypoints.count, !vm.waypoints.isEmpty {
               let startPoint = vm.waypoints[self.currentSegmentIndex]
               let endPoint = vm.waypoints[self.currentSegmentIndex + 1]
               
               let fadeOutStartIndex = self.viewModel.waypoints.count - Int(self.viewModel.fadeOutPercentage * Float(self.viewModel.waypoints.count))
               self.lastTraceNode = self.addNewBallTraceNode(with: [startPoint, endPoint])
               
               if let callback = self.ballTraceAnimationProgress {
                  callback(vm.player, vm.shotId, self.currentSegmentIndex, startPoint)
               }
               
               // Show the apex card at the highest apex point.
               if let apexNode = self.apexNode, let apexPoint = self.apexPoint {
                   if endPoint.x == apexPoint.x && endPoint.y == apexPoint.y && endPoint.z == apexPoint.z {
                       ObjectFactory.shared.sportsVenueController?.apexNodeDict[apexNode] = apexPoint
                       //sorting the dictionary and finding maximum point.
                       let apexNodes = ObjectFactory.shared.sportsVenueController?.apexNodeDict.filter{ !(ObjectFactory.shared.sportsVenueController?.hiddenTracesApexNodes.contains($0.key) ?? false) }
                       let maxApexPoint = apexNodes?.max { $0.value.z < $1.value.z }
                      ObjectFactory.shared.sportsVenueController?.setApexCard(apexPiont: maxApexPoint?.value ?? qVector3.zero)
                       ObjectFactory.shared.sportsVenueController?.golfApexCardEntity?.addApexCard(apexcard: apexNode)
                      apexNode.show()
                       
                   }
               } else {
                   if let apexPoint = self.apexPoint {
                       if endPoint.x == apexPoint.x && endPoint.y == apexPoint.y && endPoint.z == apexPoint.z {
                           if let apexNode = self.apexNodes {
                               ObjectFactory.shared.sportsVenueController?.apexNodeDict[apexNode] = apexPoint
                               if ObjectFactory.shared.sportsVenueController?.golfApexCardEntity?.apexCards.count != 0 {
                                  ObjectFactory.shared.sportsVenueController?.changeApexCardPosition()
                               }
                           }
                       }
                   }
               }
               
               if (vm.waypoints.count - self.currentSegmentIndex) == fadeOutStartIndex {
                  self.startFadeout = true
               }
               
               if self.isDotted {
                  self.currentSegmentIndex += 2
               } else {
                  self.currentSegmentIndex += 1
               }
               
               if vm.isPuttTrace {
                  self.greenPlayerCard?.viewModel.ballLiePosition = endPoint
               }
            } else {
               self.isAnimating = false
               self.animationTimer = nil
               
               if !self.hasFade {
                  if !self.isFromGreenContainer {
                     NotificationCenter.default.post(name: Notification.Name(constants.ballTraceAnimationDidCompleteNotification), object: nil, userInfo: ["player": vm.player,"shotID": vm.shotId, "isGroupReplay": self.isGroupReplay])
                  } else {
                     NotificationCenter.default.post(name: Notification.Name(constants.ballTraceAnimationOnGreenDidCompleteNotification), object: nil, userInfo: ["player": vm.player,"shotID": vm.shotId, "isGroupReplay": self.isGroupReplay])
                  }
               } else {
                  if !self.isFromGreenContainer {
                     NotificationCenter.default.post(name: Notification.Name(constants.ballTraceAnimationDidCompleteNotification), object: nil, userInfo: ["player": vm.player, "shotID": vm.shotId, "ballTrace": vm.waypoints, "isGroupReplay": self.isGroupReplay])
                  } else {
                     NotificationCenter.default.post(name: Notification.Name(constants.ballTraceAnimationOnGreenDidCompleteNotification), object: nil, userInfo: ["player": vm.player, "shotID": vm.shotId, "ballTrace": vm.waypoints, "isGroupReplay": self.isGroupReplay])
                  }
               }
               completion()
            }
         }
      })
      if let animationTimer = animationTimer {
          RunLoop.main.add(animationTimer, forMode: .common)
      }
   }
   public override func pauseAnimation() {
       if let animationTimer = animationTimer, animationTimer.isValid {
           animationTimer.fireDate = .distantFuture
       }
   }
   public func setApexPoint(apexPoint:qVector3?) {
       self.apexPoint = apexPoint
   }
   func setApex( apexNode:golfApexCard?) {
       self.apexNode = apexNode
   }
   public func setApexNode(apexNode: golfApexCard?) {
       self.apexNodes = apexNode
   }
   public override func resumeAnimation() {
       if let animationTimer = animationTimer, animationTimer.isValid {
           animationTimer.fireDate = .now
       }
   }
   
   internal func createBallForGreenModel(ballRadius: CGFloat, color: UIColor, startPosition: SIMD3<Float>) -> qEntity {
      let ball = qModelEntity(mesh: qMeshResource.generateSphere(radius: Float(ballRadius)), materials: [qUnlitMaterial(color: color)])
      ball.position = qVector3(startPosition)
      return ball
   }
   internal func createBallForActualGreen(ballRadius: CGFloat, color: UIColor) -> qEntity {
      let ball = qModelEntity(mesh: qMeshResource.generateSphere(radius: Float(ballRadius)), materials: [qUnlitMaterial(color: color)])
      return ball
   }
   internal override func createSegmentMaterial() -> qMaterial {
      if let vm = self.viewModel as? golfShotViewModel, vm.isPuttTrace {
         let material = qUnlitMaterial(color: self.viewModel.color.withAlphaComponent(CGFloat(self.viewModel.opacity)))
         return material
      } else {
         return super.createSegmentMaterial()
      }
   }
}
