import UIKit
import Q
import Q_ui

let STR_SCHEDULE = "Schedule"

class ScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var schedule: Schedule? = nil
   var selectedTournament: Tournament? = nil
   var fieldOfPlay: String = ""
   
   @IBOutlet var scheduleTableView: UITableView!
   @IBOutlet weak var msgLabel: UILabel!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.setUpNavigationBar(title: STR_SCHEDULE)
      self.setUI()
      scheduleTableView.delegate = self
      scheduleTableView.dataSource = self
      loadTournaments()
   }
   
   func loadTournaments(){
      // Get our season schedule from the app bundle.
      // In a production app this will probably be pulled from a database, API, or JSON over HTTP
      if let bundleID = Bundle.main.bundleIdentifier {
         if let jsonFile = Bundle(identifier: bundleID)!.path( forResource: "basketballSchedule", ofType: "json") {
            if let fileData = NSData(contentsOfFile: jsonFile) {
               let decoder = JSONDecoder()
               if let result = try? decoder.decode(Schedule.self, from: fileData as Data) {
                  schedule = result
               }
            }
         }
      }
      
      self.scheduleTableView.reloadData()
   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(false)
      
      self.navigationItem.title = STR_SCHEDULE
      self.tabBarController?.tabBar.isHidden = false
      loadTournaments()
   }
   @objc func onManifsetUpdated(){
      loadTournaments()
   }
   func setUI() {
      self.scheduleTableView.tableFooterView = UIView()
   }
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      guard let s = schedule else { return 0 }
      guard let t = s.tournaments else { return 0 }
      return t.count
   }
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      return setSchedule(indexPath: indexPath)
   }
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      self.tabBarController?.tabBar.isHidden = true
      
      // Set the selected tournament
      selectedTournament = schedule!.tournaments?[indexPath.row]
      
      // Set the selected field of play (fop)
      if let fop = selectedTournament?.fops?[indexPath.row].fid {
         self.fieldOfPlay = fop
         if let s = selectedTournament, let url = URL(string: s.qrealityUrl!) {
            createArExperience( for: url )
         }
      }
   }
   private func setSchedule(indexPath: IndexPath) -> ScheduleTableViewCell {
      
      // Create a new (or reuse an existing) table view cell
      let scheduleCell = scheduleTableView.dequeueReusableCell(withIdentifier: "tournamentDetailCell", for: indexPath) as! ScheduleTableViewCell
      
      if let currentTournament = schedule!.tournaments?[indexPath.row] {
         
         if let gameName = currentTournament.gna, let fops = currentTournament.fops {
            for fop in fops {
               let hole = fop.fna ?? "Hole No. 1"
               let description = currentTournament.desc ?? "Beyond description "
               scheduleCell.gameTitle.text = "\(gameName)\n\(hole)\n\(description)"
            }
            
            // TODO: This is pulling a resource from our bundle, in a production app
            // these would pull from a URL
            if let logoUrl = currentTournament.lurl {
               scheduleCell.gameLogo.image = UIImage(named: logoUrl)
            }else{
               scheduleCell.gameLogo.image = nil
            }
         }
      }
      return scheduleCell
   }
   func showMessage( _ msg: String ) {
      DispatchQueue.main.async {
         self.msgLabel.text = msg
      }
   }
   
   func createArExperience( for sdkUrl: URL ) {
      // TODO: Need to architect a better way to initialize/reference this. I don't like having this code here, seems unnecessary
      userInfo.instance.registerDefaults()
      
      experienceWrapper.instance.createAndSetExperience(
         type: basketballVenueExperienceWrapper.self, sdkUrl: sdkUrl, parent: self ) { (experience, result) in
         switch result.error {
            case .NONE:
               experience?.fop = self.fieldOfPlay // TODO: This should be optional
               experience?.requiredOrientation = .LANDSCAPE
               experience?.orientationDefinesArState = true
               
                // Handle things such as:
               // - setting user-defined experience options
               // - anything else where the experience object is required
               self.onArExperienceReady()
               
               // All good, AR experience is initialized and will be entered
               // when device is in landscape orientation
            default:
               // Something failed, errorMsg has more info
               self.onArExperienceFailed( result.errorMsg, error: result.error )
         }
      }
   }
   func onArExperienceFailed( _ msg: String, error: Q.ERROR ) {
   }
   func onArExperienceReady() {
   }
}
