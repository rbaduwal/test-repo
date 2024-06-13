import UIKit
import Q

class mainTableViewCell: UITableViewCell {
   
   var gameDataAtHole: [Q.golfPlayer] = []
   var tableViewHeight: CGFloat = 96
   @IBOutlet weak var holeNumberLabel: UILabel!
   @IBOutlet weak var parAndYdsLabel: UILabel!
   @IBOutlet weak var parAndYrdsLabel: UILabel!
   
   private var tableView: UITableView = {
      let tableView = UITableView()
      return tableView
   }()
   
   override func awakeFromNib() {
      super.awakeFromNib()
      
      tableViewSetUp()
      tableView.delegate = self
      tableView.dataSource = self

      tableView.register(UINib.fromSdkBundle("SecondryTableViewCell"), forCellReuseIdentifier: "SecondryTableViewCell")
      tableView.register(UINib.fromSdkBundle("NoPlayerMessageCell"), forCellReuseIdentifier: "NoPlayerMessageCell")
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
      self.setColor(color: UIColor(hexString: "#E8000B"))
   }
   override func prepareForReuse() {
      super.prepareForReuse()
   }
   func setColor(color:UIColor? = UIColor(hexString: "#209403")) {
      self.holeNumberLabel.backgroundColor = color
      self.parAndYdsLabel.textColor = color
      tableView.layer.borderColor = color?.cgColor
   }
   func setParAndYrds(data: liveTableUIView.liveTableDetails) {
      
      if data.hole.isFeatured {
         holeNumberLabel.text = " AR HOLE \(String(describing: data.hole.num)) "
         self.setColor(color: UIColor(hexString: "#E8000B"))
      } else {
         holeNumberLabel.text = " HOLE \(String(describing: data.hole.num)) "
         self.setColor(color: UIColor(hexString: "#209403"))
      }
      parAndYdsLabel.text = "Par \(String(describing: data.hole.par))  \(String(describing: data.hole.yards)) yrds"
      
      self.gameDataAtHole = data.players ?? []
      tableViewHeight = CGFloat(32*(data.players?.count ?? 3))
      updateTableViewConstraint(height: tableViewHeight)
      self.contentView.layoutIfNeeded()
      tableView.reloadData()
   }
   func updateTableViewConstraint(height:CGFloat) {
      
      tableView.frame = CGRect(x: 0, y: 0, width: 255, height: height)
      self.contentView.subviews.last?.constraints.first?.constant = height
   }
   func tableViewSetUp() {
      tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 255, height: tableViewHeight))
      tableView.insetsContentViewsToSafeArea = false
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.separatorColor = .clear
      tableView.allowsSelection = false
      tableView.isScrollEnabled = false
      tableView.layer.borderColor = UIColor(hexString: "#E8000B").cgColor
      tableView.layer.borderWidth = 2.0
      
      //for shadow
      let containerView:UIView = UIView(frame:self.tableView.frame)
      containerView.backgroundColor = UIColor.clear
      containerView.layer.shadowColor = UIColor.lightGray.cgColor
      containerView.layer.shadowOffset = CGSize(width: 0, height: 8);
      containerView.layer.shadowOpacity = 0.3
      containerView.layer.shadowRadius = 3
      containerView.translatesAutoresizingMaskIntoConstraints = false
      
      //for rounded corners
      tableView.layer.cornerRadius = 10
      tableView.layer.maskedCorners = [.layerMaxXMaxYCorner,.layerMinXMaxYCorner]
      tableView.layer.masksToBounds = true
      containerView.addSubview(tableView)
      self.contentView.addSubview(containerView)
      self.setTableViewConstraints(containerView: containerView)
   }
   
   func setTableViewConstraints(containerView:UIView){
      let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor,constant: -6)
      bottomConstraint.priority = UILayoutPriority(rawValue: 999)
      NSLayoutConstraint.activate([
         containerView.heightAnchor.constraint(equalToConstant: tableViewHeight),
         containerView.topAnchor.constraint(equalTo: self.contentView.topAnchor,constant: 46),
         containerView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor,constant: 10),
         bottomConstraint
      ])
   }
   
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
   }
}
extension mainTableViewCell: UITableViewDelegate, UITableViewDataSource {
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if gameDataAtHole.count == 0 {
         return 3
      } else {
         return gameDataAtHole.count
      }
   }
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if gameDataAtHole.count == 0 {
         
         if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoPlayerMessageCell", for: indexPath) as! noPlayerMessageCell
            cell.noPlayerMessageLabel.text = configurableText.instance.getText(id: .messageOnNoHole)
            return cell
         } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.frame = CGRect(x: 0, y: 0, width: 256, height: 32)
            cell.backgroundColor = .white
            return cell
         }
      } else {
         let cell = tableView.dequeueReusableCell( withIdentifier: "SecondryTableViewCell", for: indexPath) as! secondaryTableViewCell
         cell.setGameInfo(player: gameDataAtHole[indexPath.row])
         return cell
      }
   }
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 32
   }
}
