import UIKit

class playerImage: UIView {
   
   @IBOutlet weak var bottomConeImageView: UIImageView!
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet var contentView: UIView!
   let kCONTENT_XIB_NAME = "playerImage"
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      commonInit()
   }
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      commonInit()
   }
   
   func commonInit() {
      Bundle(for: type(of: self)).loadNibNamed(kCONTENT_XIB_NAME, owner: self, options: nil)
      contentView.fixInView(self)
      imageView.image = UIImage(named: "defaultPlayer", in: Bundle(identifier:constants.qUIBundleID), compatibleWith: nil)
      imageView.layer.borderWidth = 10.0
      imageView.layer.masksToBounds = false
      imageView.layer.borderColor = UIColor.yellow.cgColor
      imageView.layer.cornerRadius = imageView.frame.size.width/2
      imageView.clipsToBounds = true
   }
   
   func setData(image: UIImage, borderColor: UIColor, borderWidth: CGFloat) {
      self.imageView.image = image
      self.imageView.layer.borderWidth = borderWidth
      self.imageView.layer.masksToBounds = false
      self.imageView.layer.borderColor = borderColor.cgColor
      self.imageView.layer.cornerRadius = (self.imageView.frame.size.width)/2
      self.imageView.clipsToBounds = true
      self.bottomConeImageView.tintColor = borderColor
   }
}
