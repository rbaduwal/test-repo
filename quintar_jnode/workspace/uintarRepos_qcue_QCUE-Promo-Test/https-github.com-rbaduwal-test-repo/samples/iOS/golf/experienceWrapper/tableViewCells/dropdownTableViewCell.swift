import UIKit

class dropdownTableViewCell: UITableViewCell {
   
   @IBOutlet weak var checkLabel: UILabel!
   @IBOutlet weak var roundOrHoleLabel:UILabel!
   override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
   }
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      
      // Configure the view for the selected state
   }
   override func prepareForReuse() {
      super.prepareForReuse()
      roundOrHoleLabel.textColor = UIColor.white
      checkLabel.text = " "
   }
   func setLabel(text:String,isSelected:Bool) {
      roundOrHoleLabel.text = text
      if isSelected {
         roundOrHoleLabel.textColor = UIColor(hexString: "#FDC22D")
         checkLabel.text = "✓"
      }
   }
}
