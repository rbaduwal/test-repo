import UIKit
import Q_ui
import Q

 // TODO: This class can be made generic
class liveTableUIView: UIView {
   
   struct liveTableDetails {
      let hole: Q.golfHole
      var players: [Q.golfPlayer]?
   }
   
   var logoUrl: String = ""
   var liveDetails: [liveTableDetails] = []
   var listAutoScrolledOnce: Bool = false

   private var tableView:UITableView = {
      let tableView = UITableView()
      return tableView
   }()
   
   override func awakeFromNib() {
      super.awakeFromNib()
      tableViewSetUp()
      tableView.delegate = self
      tableView.dataSource = self
      tableView.register(UINib.fromSdkBundle("MainTableViewCell"       ), forCellReuseIdentifier: "MainTableViewCell")
      tableView.register(UINib.fromSdkBundle("GameHeaderTableViewCell" ), forCellReuseIdentifier: "GameHeaderTableViewCell")
   }
   func setGameLogo(logoUrl:String) {
      self.logoUrl = logoUrl
      self.tableView.reloadData()
   }
   func setLiveDetails(details:[liveTableDetails]) {
      self.liveDetails = details
      self.tableView.reloadData()
      if (self.window != nil) {
          scrollToCurrentLiveGroupOfSelectedHole()
      }
   }
   func tableViewSetUp() {
      //tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
      self.addSubview(tableView)
      tableView.allowsSelection = false
      tableView.insetsContentViewsToSafeArea = false
      tableView.backgroundColor = .clear
      tableView.separatorColor = .clear
      tableView.bounces = true
      tableView.backgroundColor = .clear
      tableView.showsVerticalScrollIndicator = false
      setTableViewConstraint()
   }
   func setTableViewConstraint() {
      tableView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
         tableView.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 0),
         tableView.rightAnchor.constraint(equalTo: self.rightAnchor,constant: 0),
         tableView.topAnchor.constraint(equalTo: self.topAnchor,constant: 0),
         tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: 0),
      ])
   }
   func scrollToCurrentLiveGroupOfSelectedHole() {
       if !self.listAutoScrolledOnce {
           if let liveHoleIndex = liveDetails.firstIndex(where: { liveTableViewData in
              (liveTableViewData.hole.isFeatured && liveTableViewData.hole.fop == experienceWrapper.golf?.fop)
           }) {
               self.listAutoScrolledOnce = true
               self.tableView.scrollToRow(at: IndexPath(row: liveHoleIndex, section: 1), at: .top, animated: true)
               self.layoutIfNeeded()
           }
       }
   }
}
extension liveTableUIView: UITableViewDelegate, UITableViewDataSource {
   func numberOfSections(in tableView: UITableView) -> Int {
      return 2
   }
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
      if section == 0 {
         return 1
      }
      else {
         return self.liveDetails.count//self.gameData.count
      }
   }
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
         let cell = tableView.dequeueReusableCell(withIdentifier: "GameHeaderTableViewCell") as! gameHeaderTableViewCell
         cell.setGamePoster(url: self.logoUrl)
         return cell
      }
      else {
         let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath) as! mainTableViewCell
         cell.setParAndYrds(data: liveDetails[indexPath.row])
         return cell
      }
   }
}
