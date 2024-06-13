import UIKit

class ScheduleTableViewCell: UITableViewCell {
   
   @IBOutlet weak var gameTitle: UILabel!
   @IBOutlet weak var gameLogo: UIImageView!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      addBorderToView(view: self, color: UIColor(hexString: "#afafaf"), borderWidth: 0.5, borderTo: .bottom)
   }
}
