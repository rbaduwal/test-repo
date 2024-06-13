import UIKit
import Q
import Q_ui

protocol RoundAndHoleSelectionDelegate {
   func onRoundSelected(round: Int)
   func onHoleSelected(hole: String)
}

class RoundAndHoleSelectionView: UIView {
   
   var tableView = UITableView()
   var rounds: [Q.golfRound] = []
   var holes: [Q.golfHole] = []
   var selectedRound: Int = 1
   var dropDown = Int()
   var buttonState: Bool = false
   
   @IBOutlet weak var roundButtonArrow: UIImageView!
   @IBOutlet weak var holeButtonArrow: UIImageView!
   @IBOutlet weak var liveTableViewConstraint: NSLayoutConstraint!
   @IBOutlet weak var roundDropdown: UIButton!
   @IBOutlet weak var holeDropdown: UIButton!
   var roundAndHoleSelectionDelegate: RoundAndHoleSelectionDelegate!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      setButtonBorder()
      loadTableview()
      tableView.alpha = 0
      //tableView.isHidden = true
      tableView.delegate = self
      tableView.dataSource = self
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
      tableView.register(UINib.fromSdkBundle("DropdownTableViewCell"), forCellReuseIdentifier: "DropdownTableViewCell")
   }
   func setRoundDropdownTitle(round:Int?) {
      if let round = round {
         self.roundDropdown.setTitle("Round \(round)", for: .normal)
         self.selectedRound = round
      } else {
         self.roundDropdown.setTitle("Round", for: .normal)
      }
   }
   func setHoleDropdownTitle(hole:Int?) {
      if let hole = hole {
         self.holeDropdown.setTitle("Hole \(hole)", for: .normal)
      } else {
         self.holeDropdown.setTitle("Hole", for: .normal)
      }
   }
   func setRounds(rounds: [Q.golfRound]) {
      self.rounds = rounds
      if rounds.count < 2 {
         roundDropdown.isEnabled = false
         roundButtonArrow.isHidden = true
      } else {
         roundDropdown.isEnabled = true
         roundButtonArrow.isHidden = false
      }
   }
   func setHoles(holes:[Q.golfHole]) {
      self.holes = holes
      if holes.count < 2 {
         holeDropdown.isEnabled = false
         holeButtonArrow.isHidden = true
      } else {
         holeDropdown.isEnabled = true
         holeButtonArrow.isHidden = false
      }
   }
   func loadTableview() {
      self.tableView.separatorInset.left = 0
      self.tableView.showsVerticalScrollIndicator = false
      self.tableView.insetsContentViewsToSafeArea = false
      self.tableView.bounces = false
      self.tableView.separatorColor = UIColor(hexString: "#B3C4D4")
      self.superview?.addSubview(tableView)
   }
   func dropDown(button:UIButton){
      let tableViewHeight = UIScreen.main.bounds.height
      tableView.frame = CGRect(x: self.frame.minX + 1, y: self.frame.height, width: 275, height: tableViewHeight)
      
      UIView.animate(withDuration: 0.5,delay: 0) {
         self.tableView.alpha = 1
         self.superview?.layoutIfNeeded()
      }
      
      if !UIAccessibility.isReduceTransparencyEnabled {
         tableView.backgroundColor = UIColor.clear
         let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
         let blurEffectView = CustomIntensityVisualEffectView(effect: blurEffect, intensity: 0.075)
         tableView.backgroundView = blurEffectView
      }
      self.tableView.backgroundView?.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(tableViewTapped)))

      tableView.reloadData()
   }
   @objc func tableViewTapped() {
      self.dismissDropdown()
   }
   func dismissDropdown() {
      if rounds.count < 2 {
         self.roundButtonArrow.isHidden = true
      } else {
         self.roundButtonArrow.isHidden = false
      }
      if holes.count < 2 {
         self.holeButtonArrow.isHidden = true
      } else {
         self.holeButtonArrow.isHidden = false
      }
      self.dropDown = -1
      UIView.animate(withDuration: 0.5) {
         self.tableView.alpha = 0
         self.superview?.layoutIfNeeded()
      }
      self.liveTableViewConstraint.constant = 0
   }
   func setButtonBorder() {
      let holeDropdownLeading = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: holeDropdown.frame.size.height))
      holeDropdownLeading.backgroundColor = UIColor.white
      holeDropdown.addSubview(holeDropdownLeading)
      
      let roundDropdownLeading = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: roundDropdown.frame.size.height))
      roundDropdownLeading.backgroundColor = UIColor.white
      roundDropdown.addSubview(roundDropdownLeading)
   }
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      self.tableView.isHidden = false
   }
   @IBAction func roundDropdown(_ sender: Any) {
      dropDown = 0
      self.roundButtonArrow.isHidden = true
      if holes.count > 1 {
          self.holeButtonArrow.isHidden = false
      }
      dropDown(button:sender as! UIButton)
   }
   @IBAction func holeDropdown(_ sender: Any) {
      dropDown = 1
      holeButtonArrow.isHidden = true
      if rounds.count > 1 {
         self.roundButtonArrow.isHidden = false
      }
     dropDown(button:sender as! UIButton)
   }
}
extension RoundAndHoleSelectionView: UITableViewDelegate, UITableViewDataSource {
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if dropDown == 0{
         return rounds.count
      } else {
         return holes.count
      }
   }
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "DropdownTableViewCell", for: indexPath) as! dropdownTableViewCell
      if dropDown == 0 {
         let isSelected: Bool = (self.selectedRound == rounds[indexPath.row].num)
         let round = "Round \(rounds[indexPath.row].num)"
         cell.setLabel(text: round, isSelected: isSelected)
      } else {
         let isSelected:Bool = (experienceWrapper.golf?.screenView?.selectedHoleNum ==  holes[indexPath.row].num)
         let round = "Hole \(holes[indexPath.row].num )"
         cell.setLabel(text: round, isSelected: isSelected)
      }
      return cell
   }
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if dropDown == 0 {
         self.roundButtonArrow.isHidden = false

         if self.selectedRound != rounds[indexPath.row].num {
         self.selectedRound = rounds[indexPath.row].num
            roundDropdown.setTitle("Round \(rounds[indexPath.row].num)",for:.normal)
            roundAndHoleSelectionDelegate.onRoundSelected(round: rounds[indexPath.row].num)
         }
      } else {
         self.holeButtonArrow.isHidden = false
         roundAndHoleSelectionDelegate.onHoleSelected(hole: holes[indexPath.row].fop)
      }
      UIView.animate(withDuration: 0.5) {
         self.liveTableViewConstraint.constant = 0
         tableView.alpha = 0
         self.superview?.layoutIfNeeded()
      }
   }
}
