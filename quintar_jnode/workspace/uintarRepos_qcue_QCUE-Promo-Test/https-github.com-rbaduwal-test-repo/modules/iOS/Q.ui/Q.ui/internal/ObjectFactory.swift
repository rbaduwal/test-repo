import Foundation
import UIKit
import simd

// TODO: Do we really need this? Refactor this, or at least rename it
internal class ObjectFactory: NSObject {
   
   static let shared = ObjectFactory()
   
   weak var sportsVenueController: golfVenue?
   var trackingMatrix: simd_float4x4 = matrix_identity_float4x4
   var arTextLargeFont: qMeshResource.Font?
   var arTextSmallFont: qMeshResource.Font?
   var deviceName: String {
      let deviceName = UIDevice.current.model + UIDevice.current.systemVersion
      return deviceName
   }
   
   private override init() {
   }
}
