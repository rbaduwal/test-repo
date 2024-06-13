import Foundation
import UIKit
import Q

public extension UIColor {
   convenience init(color: Q.color) {
      self.init(red: CGFloat(color.rf), green: CGFloat(color.gf), blue: CGFloat(color.bf), alpha: CGFloat(color.af))
   }
   convenience init(hexString: String, alpha: CGFloat = 1.0) {
      let c = Q.color(hexString: hexString)
      self.init(red: CGFloat(c.rf), green: CGFloat(c.gf), blue: CGFloat(c.bf), alpha: alpha)
   }
   func toHexString() -> String {
      var r:CGFloat = 0
      var g:CGFloat = 0
      var b:CGFloat = 0
      var a:CGFloat = 0
      getRed(&r, green: &g, blue: &b, alpha: &a)
      let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
      return String(format:"#%06x", rgb)
   }
}

