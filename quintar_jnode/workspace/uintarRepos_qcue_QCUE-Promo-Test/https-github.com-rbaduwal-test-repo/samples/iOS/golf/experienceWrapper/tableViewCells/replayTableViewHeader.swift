import UIKit

protocol replayTableViewHeaderDelegate {
   func sortByNames()
   func sortByPoints()
   func sortByPosition()
   func showFavoritePlayer(selection:Bool)
}

class replayTableViewHeader: UIView {
   
   var replayTableViewHeaderDelegate:replayTableViewHeaderDelegate!
   var buttonState:Bool = false
   @IBOutlet weak var postionButton: UIButton!
   @IBOutlet weak var playerButton: UIButton!
   @IBOutlet weak var totButton: UIButton!
   @IBOutlet weak var favoriteButton: UIButton!
   
   override func awakeFromNib() {
      self.postionButton.backgroundColor = UIColor(hexString: "#CCD8E2")
      self.setLines()
   }
   
   func setLines() {
      
      let favoriteButtonBottomLine = UIView(frame: CGRect(x: 0, y: 43, width: 44, height: 1))
      favoriteButtonBottomLine.backgroundColor = UIColor(hexString: "#99B0C6")
      favoriteButton.addSubview(favoriteButtonBottomLine)
      
      let postionButtonLineLeading = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: self.bounds.height))
      postionButtonLineLeading.backgroundColor = UIColor(hexString: "#99B0C6")
      postionButton.addSubview(postionButtonLineLeading)
      
      let postionButtonLineTrailing = UIView(frame: CGRect(x: 43, y: 0, width: 1, height: self.bounds.height))
      postionButtonLineTrailing.backgroundColor = UIColor(hexString: "#99B0C6")
      postionButton.addSubview(postionButtonLineTrailing)
      
      let postionButtonLineBottom = UIView(frame: CGRect(x: 0, y: 43, width: 44, height: 1))
      postionButtonLineBottom.backgroundColor = UIColor(hexString: "#99B0C6")
      postionButton.addSubview(postionButtonLineBottom)
      
      let playerButtonLineTrailing = UIView(frame: CGRect(x: 142, y: 0, width: 1, height: self.bounds.height))
      playerButtonLineTrailing.backgroundColor = UIColor(hexString: "#99B0C6")
      playerButton.addSubview(playerButtonLineTrailing)
      
      let playerButtonLineBottom = UIView(frame: CGRect(x: 0, y: 43, width: 143, height: 1))
      playerButtonLineBottom.backgroundColor = UIColor(hexString: "#99B0C6")
      playerButton.addSubview(playerButtonLineBottom)
      
      let totButtonLineBottom = UIView(frame: CGRect(x: 0, y: 43, width: 44, height: 1))
      totButtonLineBottom.backgroundColor = UIColor(hexString: "#99B0C6")
      totButton.addSubview(totButtonLineBottom)
   }
   @IBAction func positionButtonAction(_ sender: Any) {
      
      self.postionButton.backgroundColor = UIColor(hexString: "#CCD8E2")
      self.playerButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.totButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.favoriteButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.buttonState = true
      favoriteButton.setImage(UIImage.fromSdkBundle(named: "starUnselected"), for: .normal)
      replayTableViewHeaderDelegate.sortByPosition()
   }
   @IBAction func playerButtonAction(_ sender: Any) {
      
      self.postionButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.playerButton.backgroundColor = UIColor(hexString: "#CCD8E2")
      self.totButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.favoriteButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.buttonState = false
      favoriteButton.setImage(UIImage.fromSdkBundle(named: "starUnselected"), for: .normal)
      replayTableViewHeaderDelegate.sortByNames()
   }
   @IBAction func totButtonAction(_ sender: Any) {
      
      self.postionButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.playerButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.totButton.backgroundColor = UIColor(hexString: "#CCD8E2")
      self.favoriteButton.backgroundColor = UIColor(hexString: "#E5EBF1")
      self.buttonState = false
      favoriteButton.setImage(UIImage.fromSdkBundle(named: "starUnselected"), for: .normal)
      replayTableViewHeaderDelegate.sortByPoints()
   }
   @IBAction func favoriteButtonAction(_ sender: Any) {
      if !buttonState {
         self.favoriteButton.backgroundColor = UIColor(hexString: "#CCD8E2")
         self.postionButton.backgroundColor = UIColor(hexString: "#E5EBF1")
         self.playerButton.backgroundColor = UIColor(hexString: "#E5EBF1")
         self.totButton.backgroundColor = UIColor(hexString: "#E5EBF1")
         self.buttonState = true
         replayTableViewHeaderDelegate.showFavoritePlayer(selection: self.buttonState)
      } else {
         self.buttonState = false
         replayTableViewHeaderDelegate.showFavoritePlayer(selection: self.buttonState)
      }
   }
}
