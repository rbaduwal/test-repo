import UIKit
import Q
import Q_ui
import Kingfisher

class playedThroughCell: UITableViewCell {
   
   @IBOutlet weak var isFavStarImageView: UIImageView!
   @IBOutlet weak var playerImage: UIImageView!
   @IBOutlet weak var playerName: UILabel!
   @IBOutlet weak var view_Player: UIView!
   @IBOutlet weak var underLine: UIView!
   @IBOutlet weak var underLineBottomConstraint: NSLayoutConstraint!
   var isPressed:Bool = false
   var borderColor:UIColor = .clear
   var selectedImage: UIImage? = nil
   var unSelectedImage: UIImage? = nil
   
   override func awakeFromNib() {
      super.awakeFromNib()
      setProfileImage()
   }
   override func prepareForReuse() {
      super.prepareForReuse()
      self.playerName.text = ""
      self.selectedImage = nil
      self.unSelectedImage = nil
      self.playerImage.kf.cancelDownloadTask()
      self.playerImage.image = UIImage.fromSdkBundle(named: "defaultPlayer")
      self.view_Player.backgroundColor = UIColor(hexString: "#c4c4c4")
   }
   fileprivate func updatePlayerImage(_ player: Q.golfPlayer) {
      let selected = experienceWrapper.golf?.screenView?.playerContainerView.ifFavoritedPlayerSelected(player: player) ?? false
      if selected {
         self.view_Player.layer.borderColor =  UIColor( hexString:player.colors.first?.hexString ?? "#FF0000").cgColor
         
         if let image = self.selectedImage {
            playerImage.image = image
         }
      } else {
         self.view_Player.layer.borderColor = UIColor(hexString: "#808080").cgColor
         if let image = self.unSelectedImage {
            playerImage.image = image
         }
      }
   }
   fileprivate func setImage(_ player: Q.golfPlayer) {
      if selectedImage != nil {
         updatePlayerImage(player)
         self.view_Player.backgroundColor = .white
      } else {
         self.selectedImage = UIImage.fromSdkBundle(named: "defaultPlayer")
         self.unSelectedImage = self.selectedImage
         if let imageUrl = URL(string: player.hsUrl) {
            let resource = ImageResource(downloadURL: imageUrl)
            KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { kfResult in
               switch kfResult {
               case .success(let value):
                  self.selectedImage = value.image
                  if let image = self.selectedImage {
                     self.unSelectedImage = self.grayscaleImage(image: image)
                  }
                  self.updatePlayerImage(player)
                  self.view_Player.backgroundColor = .white
               case .failure(let error):
                  DispatchQueue.main.async {
                      self.updatePlayerImage(player)
                      self.view_Player.backgroundColor = UIColor(hexString: "#c4c4c4")
                  }
                  print("Error: \(error)")
               }
            }
         } else {
            DispatchQueue.main.async {
                self.updatePlayerImage(player)
                self.view_Player.backgroundColor = UIColor(hexString: "#c4c4c4")
            }
         }
      }
   }
   func setPlayer(player: Q.golfPlayer, isFavorited: Bool) {
      let selected = experienceWrapper.golf?.screenView?.playerContainerView.ifFavoritedPlayerSelected(player: player) ?? false
      setImage(player)
      
      if isFavorited {
         isFavStarImageView.isHidden = false
         playerName.text = player.sn + "\nRound \(player.team?.round.num ?? 1)"
      } else {
         isFavStarImageView.isHidden = true
         playerName.text = player.sn
      }
      
      if selected {
          self.borderColor =  UIColor( hexString:player.colors.first?.hexString ?? "#FF0000")
          self.setAsSelected()
      } else {
          self.setAsUnselected()
      }
   }
   func setProfileImage(color: UIColor? = .clear) {
      setPlayerProfileBorderView(imageView: view_Player, color: UIColor(hexString: "#808080"))
      playerImage.layer.borderWidth = 2
      playerImage.layer.masksToBounds = false
      playerImage.layer.borderColor = color?.cgColor
      playerImage.layer.cornerRadius = playerImage.frame.size.width/2
      playerImage.clipsToBounds = true
   }
   func setAsSelected() {
      self.view_Player.layer.borderColor = borderColor.cgColor
      self.isPressed = true
   }   
   func setAsUnselected() {
      self.view_Player.layer.borderColor = UIColor(hexString: "#808080").cgColor
      self.isPressed = false
   }    
   func grayscaleImage(image: UIImage) -> UIImage? {
      let ciImage = CIImage(image: image)
      if let grayscale = ciImage?.applyingFilter("CIColorControls",
                                                 parameters: [ kCIInputSaturationKey: 0.0 ]) {
         return UIImage(ciImage: grayscale)
      }
      return nil
   }
   func setPlayerProfileBorderView(imageView: UIView, color:UIColor? = .clear) {
      imageView.layer.borderWidth = 2.0
      imageView.layer.masksToBounds = false
      imageView.layer.borderColor = color?.cgColor
      imageView.layer.cornerRadius = imageView.frame.size.width/2
      imageView.clipsToBounds = true
   }
}
