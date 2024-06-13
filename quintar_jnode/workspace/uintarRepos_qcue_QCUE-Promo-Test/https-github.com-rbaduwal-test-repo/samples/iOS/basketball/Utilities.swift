import Foundation
import UIKit

func getDate(date: String) -> Date? {
   let dateFormatter = DateFormatter()
   dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
   dateFormatter.timeZone = TimeZone.init(abbreviation: "GMT")
   dateFormatter.locale = Locale.current
   return dateFormatter.date(from: date) // replace Date String
}

enum border {
   case top
   case right
   case left
   case bottom
}
func addBorderToView(view: UIView, color: UIColor, borderWidth: CGFloat, borderTo: border) {
   let border = UIView()
   border.backgroundColor = color
   
   switch borderTo {
   case .top:
      border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
      border.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: borderWidth)
   case .bottom:
      border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
      border.frame = CGRect(x: 0, y: view.frame.size.height - borderWidth, width: view.frame.size.width, height: borderWidth)
   case .left:
      border.frame = CGRect(x: 0, y: 0, width: borderWidth, height: view.frame.size.height)
      border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
   case .right:
      border.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
      border.frame = CGRect(x: view.frame.size.width - borderWidth, y: 0, width: borderWidth, height: view.frame.size.height)
   }
   
   view.addSubview(border)
}


