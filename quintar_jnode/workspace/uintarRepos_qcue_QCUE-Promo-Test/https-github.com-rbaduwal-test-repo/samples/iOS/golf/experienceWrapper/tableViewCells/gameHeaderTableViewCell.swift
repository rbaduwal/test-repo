import UIKit

class gameHeaderTableViewCell: UITableViewCell {
   
   @IBOutlet weak var gameLogoImageView: UIImageView!
   
   override func awakeFromNib() {
      super.awakeFromNib()
   }
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
   }
   func setGamePoster(url:String) {
      
      let imageUrl = URL(string: url)
      gameLogoImageView.kf.setImage(with:imageUrl , placeholder: nil, options: nil, completionHandler: nil)
   }
}
