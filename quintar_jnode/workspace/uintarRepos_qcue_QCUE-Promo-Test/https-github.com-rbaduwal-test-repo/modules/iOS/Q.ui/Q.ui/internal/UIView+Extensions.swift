import Foundation
import UIKit

internal extension UIView {
   func asImage() -> UIImage {
      if #available(iOS 10.0, *) {
         let renderer = UIGraphicsImageRenderer(bounds: bounds)
         return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
         }
      } else {
         UIGraphicsBeginImageContext(self.frame.size)
         self.layer.render(in:UIGraphicsGetCurrentContext()!)
         let image = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         // TO-DO
         return UIImage(cgImage: image!.cgImage!)
      }
   }
   func fixInView(_ container: UIView!) -> Void{
      self.translatesAutoresizingMaskIntoConstraints = false;
      self.frame = container.frame;
      container.addSubview(self);
      NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
      NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
      NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
      NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
   }
}
