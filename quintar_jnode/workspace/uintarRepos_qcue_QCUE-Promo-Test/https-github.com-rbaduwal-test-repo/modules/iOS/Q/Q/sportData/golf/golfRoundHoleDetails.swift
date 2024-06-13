import propsyncSwift

public class roundHoleDetails {
   public var roundNum: Int { self.roundHoleDetailsProps["num"]?.get() ?? -1 }
   public var pinLocation: SIMD3<Double> {
      if let l: [Double] = roundHoleDetailsProps["pinLocation"]?.get() {
         return utility.array2vec(l)
      } else {
         return SIMD3<Double>()
      }
   }
   public var teeBoxLocation: SIMD3<Double> {
      if let l: [Double] = roundHoleDetailsProps["teeBoxLocation"]?.get() {
         return utility.array2vec(l)
      } else {
         return SIMD3<Double>()
      }
   }
   public var completedGroups: [Int] {
      if let got: [UInt8] = self.roundHoleDetailsProps["completedGroups"]?.get() {
         return got.map{ Int($0) }
      } else {
         return []
      }
   }
   public var groupOrder: [Int] {
      if let got: [UInt8] = self.roundHoleDetailsProps["groupOrder"]?.get() {
         return got.map{ Int($0) }
      } else {
         return []
      }
   }
   public private(set) var roundHoleDetailsProps: property
   
   public init( roundHoleDetailsProps: property ) {
      self.roundHoleDetailsProps = roundHoleDetailsProps
   }
}
