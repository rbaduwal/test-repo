public extension Float {
   var feetToMeter: Float {
      return constants.feetToMeter
   }
   func roundToDecimal(_ fractionDigits: Int) -> Float {
      let multiplier = pow(10, Float(fractionDigits))
      return Darwin.round(self * multiplier) / multiplier
   }
   var convertedToFeetAndInches: String {
      if self < 1.0 {
         return "\(Int(self * constants.feetToInch))”"
      } else {
         let inchValue =  self.truncatingRemainder(dividingBy: self.rounded(.towardZero)) * constants.feetToInch
         return "\(Int(self))’ \(Int(inchValue))”"
      }
   }
   var convertedToYardAndFeet: String {
      if self < 3.0{
         return self.convertedToFeetAndInches
      }else{
         return "\(Int(self * constants.feetToYard)) yds"
      }
   }
   var roundedToSingleDecimal: String {
      return roundTo(1)
   }
   fileprivate func roundTo(_ decimalPlace:Int) -> String {
      return String(format: "%0.\(decimalPlace)f", self)
   }
   var degreesToRadians: Self { self * .pi / 180 }
   var radiansToDegrees: Self { self * 180 / .pi }
}
