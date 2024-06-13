import UIKit

public class teamCollectionViewCell: UICollectionViewCell {
   
   @IBOutlet weak var teamImageView: UIImageView!
   @IBOutlet weak var bgView: UIView!
   
   @IBOutlet weak var nameLabel: UILabel!
   
   public override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
   }
   public override func layoutSubviews() {
      super.layoutSubviews()
      bgView.layer.cornerRadius = bgView.frame.height / 2
      teamImageView.layer.cornerRadius = teamImageView.frame.height / 2
   }
   func hidesLabel(_ hide: Bool) {
      nameLabel.isHidden = hide
   }
}
