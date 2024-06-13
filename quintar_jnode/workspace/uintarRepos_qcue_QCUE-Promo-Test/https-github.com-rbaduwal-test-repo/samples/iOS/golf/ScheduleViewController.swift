import UIKit
import Q_ui
import Q

class ScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   private var schedule: Schedule? = nil
   private var selectedTournament: Tournament? = nil
   private var isLandscape: Bool = false
   private var fieldOfPlay: String = ""
   private var isShowingSheet = false

   @IBOutlet var scheduleTableView: UITableView!
   @IBOutlet weak var msgLabel: UILabel!
   @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
   @IBOutlet weak var versionButton: UIButton!
   @IBOutlet weak var testModeButton: UIButton!
   @IBAction func versionTapped(_ sender: Any) {
      let viewControllerToPresent = SettingsViewController()
      if let sheet = viewControllerToPresent.sheetPresentationController {
         sheet.detents = [.medium(), .large()]
         sheet.largestUndimmedDetentIdentifier = .medium
         sheet.prefersScrollingExpandsWhenScrolledToEdge = false
         sheet.prefersEdgeAttachedInCompactHeight = true
         sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
      }
      isShowingSheet = true
      present(viewControllerToPresent, animated: true, completion: nil)
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.setUpNavigationBar(title: STR_SCHEDULE)
      self.setUI()
      scheduleTableView.delegate = self
      scheduleTableView.dataSource = self
      loadTournaments()
      versionButton.setTitle("v \(UIApplication.release)", for: .normal)
   }
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(false)
      
      self.navigationItem.title = STR_SCHEDULE
      self.tabBarController?.tabBar.isHidden = false
      self.loadingIndicator.stopAnimating()
      self.loadingIndicator.isHidden = true
      let transform: CGAffineTransform = CGAffineTransform(scaleX: 3, y: 3)
      self.loadingIndicator.transform = transform
      self.loadingIndicator.center = self.view.center
      loadTournaments()
   }
   
   func loadTournaments(){
      // Get our season schedule from the app bundle.
      // In a production app this will probably be pulled from a database, API, or JSON over HTTP
      if let bundleID = Bundle.main.bundleIdentifier {
         if let jsonFile = Bundle(identifier: bundleID)!.path( forResource: "golfSchedule", ofType: "json") {
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
      
      guard let s = schedule else { return }
      guard let t = s.tournaments else { return }
      
      self.selectedTournament = t[indexPath.row]

      // Try to enter AR
      if let st = self.selectedTournament,
         let url = URL(string: st.qrealityUrl!) {
         
         self.loadingIndicator.isHidden = false
         self.loadingIndicator.startAnimating()
         createArExperience( for: url )
      }
   }
   func setSchedule(indexPath: IndexPath) -> ScheduleTableViewCell {
      
      // Create a new (or reuse an existing) table view cell
      let scheduleCell = scheduleTableView.dequeueReusableCell(withIdentifier: "tournamentDetailCell", for: indexPath) as! ScheduleTableViewCell
      if let t = schedule?.tournaments?[indexPath.row],
         let gameName = t.gna {
         
         let description = t.desc ?? "Beyond description "
         if let fops = t.fops {
            var fopList: String = ""
            for fop in fops {
               if let fid = fop.fid {
                  fopList += "\(fid)  "
               } else {
                  fopList += "unknown hole  "
               }
            }
            scheduleCell.gameTitle.text = "\(gameName)\n\(fopList)\n\(description)"
         } else {
            scheduleCell.gameTitle.text = "\(gameName)\n\(description)"
         }
         
         // TODO: This is pulling a resource from our bundle, but in a production app these would pull from a URL
         if let logoUrl = t.lurl {
            scheduleCell.gameLogo.image = UIImage.fromSdkBundle(named: logoUrl)
         } else {
            scheduleCell.gameLogo.image = nil
         }
      }
      return scheduleCell
   }
   func createArExperience( for sdkUrl: URL ) {
      experienceWrapper.instance.createAndSetExperience(
         type: golfVenueExperienceWrapper.self, sdkUrl: sdkUrl, parent: self ) { (experience, result) in
         switch result.error {
            case .NONE:
               experience?.requiredOrientation = .LANDSCAPE
               experience?.orientationDefinesArState = true
               
               // Handle things such as:
               // - setting user-defined experience options
               // - anything else where the experience object is required
               self.onArExperienceReady()
               
               // All good! The AR experience is initialized and will be entered
               // when the device is in landscape orientation
            default:
               // Something failed, errorMsg has more info
               self.onArExperienceFailed( result.errorMsg, error: result.error )
         }
      }
   }
   func onArExperienceFailed( _ msg: String, error: Q.ERROR ) {
      switch error {
         case .NETWORK_ERROR:
            DispatchQueue.main.async {
               self.showAlert(message: configurableText.instance.getText(id: .networkNotAvailableMessage), title: "")
            }
         default:
            DispatchQueue.main.async {
               self.msgLabel.text = msg
            }
      }
      dismissActivityIndicator()
   }
   func onArExperienceReady() {
      SettingsViewController.apply()
      dismissActivityIndicator()
   }
   func dismissSheet() {
      isShowingSheet = false
      dismiss(animated: true, completion: nil)
   }
   func dismissActivityIndicator() {
      DispatchQueue.main.async {
         self.loadingIndicator.isHidden = true
         self.loadingIndicator.stopAnimating()
      }
   }
   func showAlert(message: String, title: String) {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
   }
}

extension UIApplication {
   static var release: String {
      return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "x.x"
   }
   static var build: String {
      return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "x"
   }
   static var version: String {
      return "\(release).\(build)"
   }
}
