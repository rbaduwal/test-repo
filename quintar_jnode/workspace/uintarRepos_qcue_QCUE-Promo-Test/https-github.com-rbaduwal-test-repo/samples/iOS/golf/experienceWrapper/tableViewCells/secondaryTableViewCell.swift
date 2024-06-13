import UIKit
import Q

class secondaryTableViewCell: UITableViewCell {
   
   @IBOutlet weak var positionLabel: UILabel!
   @IBOutlet weak var playerNameLabel: UILabel!
   @IBOutlet weak var totalPointLabel: UILabel!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
   }
   override func prepareForReuse() {
      super.prepareForReuse()
      self.positionLabel.text = ""
      self.playerNameLabel.text = ""
      self.totalPointLabel.text = ""
   }
   func setGameInfo( player: Q.golfPlayer ) {
      self.playerNameLabel.text = "\(player.sn), \(player.fn.uppercased().first ?? " ")"
      self.totalPointLabel.text = Q.golfPlayer.score2str( player.score )
      if let position = player.position {
         self.positionLabel.text = (player.isTied ? "T" : "") + "\(position)"
      } else {
         self.positionLabel.text = ""
      }
   }
   
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
   }
}
