import UIKit
import Q

class replayTableViewCell: UITableViewCell {
   
   @IBOutlet weak var favoriteButton: UIButton!
   @IBOutlet weak var positionLabel: UILabel!
   @IBOutlet weak var playerNameLabel: UILabel!
   @IBOutlet weak var pointsLabel: UILabel!
   var buttonState:Bool = false
   
   override func awakeFromNib() {
      super.awakeFromNib()
   }
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      
      // Configure the view for the selected state
   }
   override func prepareForReuse() {
      super.prepareForReuse()
      favoriteButton.setImage(UIImage.fromSdkBundle(named: "starUnselected"), for: .normal)
      self.pointsLabel.text = ""
      self.playerNameLabel.text = ""
      self.positionLabel.text = ""
   }
   func setDetails(player: Q.golfPlayer, isFavorited: Bool) {
      if let score = player.score {
         self.pointsLabel.text = (score == 0) ? "E" : (score>0) ? "+\(score)" : "\(score)"
      } else {
         self.pointsLabel.text = "--"
      }
      self.playerNameLabel.text = "\(player.sn), \(player.fn.uppercased().first ?? " ")"
      if let position = player.position {
         if player.isTied {
            self.positionLabel.text = "T" + String(position)
         } else {
            self.positionLabel.text = String(position)
         }
      } else {
         self.positionLabel.text = " "
      }
      
      if isFavorited {
         favoriteButton.setImage(UIImage.fromSdkBundle(named: "starSelected"), for: .normal)
         self.buttonState = true
      } else {
         favoriteButton.setImage(UIImage.fromSdkBundle(named: "starUnselected"), for: .normal)
      }
   }
}
