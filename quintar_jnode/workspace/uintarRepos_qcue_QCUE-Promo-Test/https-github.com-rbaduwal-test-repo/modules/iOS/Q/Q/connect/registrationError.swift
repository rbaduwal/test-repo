import Foundation
public struct registrationError: CustomStringConvertible {

   var error: String?
   var errorCode: String?
   var numberOfFeatures: Int?
   var numberOfMatches: Int?
   var numberOfVisible3DPoints: Int?
   
   public var description: String {
      return "Registration error (\(errorCode ?? "?")): \(error ?? "?")"
   }
}
