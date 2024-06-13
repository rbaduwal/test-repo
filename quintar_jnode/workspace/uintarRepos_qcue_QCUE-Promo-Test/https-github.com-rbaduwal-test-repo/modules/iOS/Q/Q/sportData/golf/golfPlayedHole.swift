import propsyncSwift

public class golfPlayedHole {

   public var num: Int { self.playerHoleProps["num"]?.get() ?? -1 }
   public var scoreAtTee: Int { self.playerHoleProps["scoreAtTee"]?.get() ?? 0 }
   public var positionAtTee: Int { self.playerHoleProps["positionAtTee"]?.get() ?? 0 }
   public var scoreAfterHole: Int? { self.playerHoleProps["scoreAfterHole"]?.get() }
   public var positionAfterHole: Int? { self.playerHoleProps["positionAfterHole"]?.get() }
   public var isTiedAfterHole: Bool { self.playerHoleProps["isTiedAfterHole"]?.get() ?? false }
   public var puttTraceIndex: Int? {
      if let shotIndex = shots.firstIndex(where: {$0.lieTurf.contains(word: "green")}) {
           let putttraceIndex = shotIndex + 1
           if putttraceIndex < shots.count {
               return putttraceIndex
           }
       }
       return nil
   }
   public var teeShotIndex: Int? {
      var teeShotIndex = 0
      let shotIndex = shots.lastIndex(where: {$0.penalty})
      if let indexOfPenality = shotIndex {
         teeShotIndex = indexOfPenality + 1
      }
      if teeShotIndex < shots.count {
         return teeShotIndex
      } else {
         return nil
      }
   }
   public var combinedTrace: [SIMD3<Double>] {
      var returnValue = [SIMD3<Double>]()
      for index in 0 ..< shots.count {
         returnValue.append(contentsOf: shots[index].trace)
      }
      return returnValue
   }
   public private(set) var shots: [golfShot] = []
   public private(set) var playerHoleProps: property
   public var shotAdded: ((golfShot) ->())? = nil
   private let sportData: sportData

   public init( sportData: sportData, playerHoleProps: property ) {
      self.sportData = sportData
      self.playerHoleProps = playerHoleProps
      self.playerHoleProps.childAdded = self.onChildAdded
   }
   
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {
         case "shots":
            p.childAdded = onShotAdded
         default: break
      }
   }
   private func onShotAdded( xpath: String, p: property ) {
      if let shotId: Int = p["shotId"]?.get(), !self.shots.contains( where: {$0.shotId == shotId} ) {
         let shot = golfShot( sportData: sportData, shotType: determineNextShotType(), shotProps: p )
         self.shots.append( shot )
         triggerShotAdded( newShot: shot )
      }
   }
   private func triggerShotAdded(newShot: golfShot) {
      if let callback = shotAdded {
         callback( newShot )
      }
   }
   // TODO: deprecate this in favor of shot type being sent in the data
   private func determineNextShotType() -> golfShot.TYPE {
      var shotType = golfShot.TYPE.TEE
      if let lastShot = shots.last {
         if self.puttTraceIndex != nil {
            shotType = .PUTT
         } else if !lastShot.penalty {
            shotType = .CHIP
         }
      }
      return shotType
   }
}
