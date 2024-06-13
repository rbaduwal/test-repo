import UIKit

class teamPlayerImage: UIView {
   
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet var contentView: UIView!
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
      imageView.image = UIImage(named: "defaultPlayer", in: Bundle(identifier:constants.qUIBundleID), compatibleWith: nil)
      imageView.frame = self.frame
   }
   
   func setData(image: UIImage, borderColor: UIColor, borderWidth: CGFloat, isTeamLogo: Bool) {
      self.imageView.image = image
      
      if !isTeamLogo {
         self.imageView.layer.borderWidth = borderWidth
         self.imageView.layer.masksToBounds = false
         self.imageView.layer.borderColor = borderColor.cgColor
         self.imageView.layer.cornerRadius = (self.imageView.frame.size.width)/2
         self.imageView.clipsToBounds = true
      }
   }
}


