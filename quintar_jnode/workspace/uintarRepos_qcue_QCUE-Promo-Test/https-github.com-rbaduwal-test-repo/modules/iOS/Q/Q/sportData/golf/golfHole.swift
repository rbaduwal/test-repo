import propsyncSwift

public class golfHole {

   public var num: Int { self.holeProps["num"]?.get() ?? -1 }
   public var isFeatured: Bool { self.holeProps["isFeatured"]?.get() ?? false }
   public var fop: String { self.holeProps["id"]?.get() ?? "" }
   public var par: Int { self.holeProps["par"]?.get() ?? -1 }
   public var yards: Int { self.holeProps["yards"]?.get() ?? -1 }
   public var currentRound: Int { self.holeProps["currentRound"]?.get() ?? -1 }
   public var groupsOnTee: [Int] {
      if let got: [UInt8] = self.holeProps["groupsOnTee"]?.get() {
         return got.map{ Int($0) }
      } else {
         return []
      }
   }
   public var groupOnApproach: Int { self.holeProps["groupOnApproach"]?.get() ?? -1 }
   public var groupOnGreen: Int { self.holeProps["groupOnGreen"]?.get() ?? -1 }
   public var previousGroup: Int { self.holeProps["previousGroup"]?.get() ?? -1 }
   public var liveGroups: [Int] {
      var returnValue: [Int] = []
      
      // Append such that green is first, approach second, tee last
      if groupOnGreen != 0 { returnValue.append(groupOnGreen) }
      if groupOnApproach != 0 { returnValue.append(groupOnApproach) }
      for group in groupsOnTee.reversed() { returnValue.append(group) }
      
      return returnValue
   }
   public private(set) var roundHoleDetails: [roundHoleDetails] = []
   public private(set) var holeProps: property
   private let sportData: sportData
   
   init( sportData: sportData, holeProps: property ) {
      self.sportData = sportData
      self.holeProps = holeProps
      self.holeProps.childAdded = onChildAdded
   }
   
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {
         case "rounds":
            for r in p {
               if let roundNum: Int = r["num"]?.get(), !self.roundHoleDetails.contains( where: {$0.roundNum == roundNum} ) {
                  self.roundHoleDetails.append( Q.roundHoleDetails(roundHoleDetailsProps: r) )
               }
            }
         case "groupsOnTee",
            "groupOnApproach",
            "groupOnGreen":
            triggerGroupLocationChanged()
         default: break
      }
   }
   private func triggerGroupLocationChanged() {
      self.sportData.postNotification(name: constants.groupLocationChangedNotification,
         object: nil,
         userInfo: ["data": self],
         canDefer: true)
   }
}
