import propsyncSwift

public class golfCourse {

   // golfCourse stuff
   public var num: Int { self.courseProps["num"]?.get() ?? -1 }
   public var city: String { self.courseProps["ci"]?.get() ?? "" }
   public var state: String { self.courseProps["stt"]?.get() ?? "" }
   public var venue: String { self.courseProps["vna"]?.get() ?? "" }
   public var featuredHoles: [golfHole] { self.holes.filter({ hole in hole.isFeatured == true }) }
   public private(set) var holes: [golfHole] = []
   public private(set) var courseProps: property
   private let sportData: sportData
   
   init( sportData: sportData, courseProps: property ) {
      self.sportData = sportData
      self.courseProps = courseProps
      self.courseProps.childAdded = onChildAdded
   }
   
   private func onChildAdded( xpath: String, p: property ) {
      switch p.key {
      
         case "holes":
            for h in p {
               if let holeNum: Int = h["num"]?.get(), !self.holes.contains( where: {$0.num == holeNum} ) {
                  self.holes.append( golfHole( sportData: sportData, holeProps: h ) )
               }
            }
            
         default: break
      }
   }
}
