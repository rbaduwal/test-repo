import propsyncSwift

public class golfRound {

   // Golf stuff
   public var num: Int { self.roundProps["num"]?.get() ?? -1 }
   public private(set) var groups: [Int:golfGroup] = [:]
   public private(set) var roundProps: property
   private let sportData: sportData
   
   init( sportData: sportData, roundProps: property ) {
      self.sportData = sportData
      self.roundProps = roundProps
      self.roundProps.childAdded = onChildAdded
   }
   public func orderedGroups(forHole: golfHole) -> [golfGroup] {
      var sortedGroups = [golfGroup]()

      let groupOrder = forHole.roundHoleDetails[ num - 1 ].groupOrder
      if !groupOrder.isEmpty {
         for gid in groupOrder {
            if let group = groups[gid] {
               sortedGroups.append(group)
            }
         }
      } else {
         for group in groups {
            sortedGroups.append(group.value)
         }
      }
      return sortedGroups
   }
   
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {

         case "groups":
            p.childAdded = onGroupAdded
            
         default: break
      }
   }
   private func onGroupAdded( xpath: String, groupProps: property ) {
      if let groupNum: Int = groupProps["num"]?.get(), self.groups[groupNum] == nil {
         self.groups[groupNum] = golfGroup( sportData: sportData, round: self, groupProps: groupProps )
      }
   }
}
