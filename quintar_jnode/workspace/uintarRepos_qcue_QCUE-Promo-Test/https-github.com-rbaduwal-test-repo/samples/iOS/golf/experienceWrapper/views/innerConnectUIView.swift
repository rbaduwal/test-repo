import UIKit

class InnerConnectUIView: UIView {
   
   @IBOutlet weak var leftVector: UIView!
   @IBOutlet weak var leftVectorTop: UIView!
   @IBOutlet weak var leftVectorBottom: UIView!
   @IBOutlet weak var rightVector: UIView!
   @IBOutlet weak var rightVectorBottom: UIView!
   @IBOutlet weak var rightVectorTop: UIView!
   @IBOutlet weak var constraint_WidthConnectView: NSLayoutConstraint!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      
      constraint_WidthConnectView.constant = 453
      setVectorCornerRadius()
   }
   
   private func setVectorCornerRadius() {
      self.leftVectorTop.layer.cornerRadius = self.leftVectorTop.bounds.height/2
      self.leftVectorTop.layer.maskedCorners = [.layerMaxXMinYCorner,.layerMaxXMaxYCorner]
      self.leftVectorBottom.layer.cornerRadius = self.leftVectorBottom.bounds.height/2
      self.leftVectorBottom.layer.maskedCorners = [.layerMaxXMinYCorner,.layerMaxXMaxYCorner]
      self.rightVectorTop.layer.cornerRadius = self.rightVectorTop.bounds.height/2
      self.rightVectorTop.layer.maskedCorners = [.layerMinXMinYCorner,.layerMinXMaxYCorner]
      self.rightVectorBottom.layer.cornerRadius = self.rightVectorTop.bounds.height/2
      self.rightVectorBottom.layer.maskedCorners = [.layerMinXMinYCorner,.layerMinXMaxYCorner]
   }
   public func changeVectorColor(color:UIColor) {
      self.leftVector.backgroundColor = color
      self.leftVectorTop.backgroundColor = color
      self.leftVectorBottom.backgroundColor = color
      self.rightVector.backgroundColor = color
      self.rightVectorTop.backgroundColor = color
      self.rightVectorBottom.backgroundColor = color
   }
}
