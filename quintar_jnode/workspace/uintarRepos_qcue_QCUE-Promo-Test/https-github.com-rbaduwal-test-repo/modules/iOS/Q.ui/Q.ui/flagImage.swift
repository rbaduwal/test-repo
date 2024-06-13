import UIKit

class flagImage: UIView {
   
   @IBOutlet var contentView: UIView!
   @IBOutlet weak var imageView: UIImageView!
   
   let kCONTENT_XIB_NAME = "teamPlayerImage"
   
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
      imageView.image = UIImage(named: "flag", in: Bundle(identifier:constants.qUIBundleID), compatibleWith: nil)
      imageView.frame = self.frame
      imageView.contentMode = .scaleAspectFit
      imageView.backgroundColor = .clear
   }
   
   func setData(image: UIImage, borderColor: UIColor, borderWidth: CGFloat) {
      self.imageView.image = image
      self.imageView.layer.borderWidth = borderWidth
      self.imageView.layer.masksToBounds = false
      self.imageView.layer.borderColor = borderColor.cgColor
      self.imageView.clipsToBounds = true
   }
}


