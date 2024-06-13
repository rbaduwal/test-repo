import UIKit
import Q_ui
import Q

public class bottomControlPanel: UIView {
  
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet var roundButtons: [UIButton]!
   @IBOutlet var shotTypeButtons: [UIButton]!
   @IBOutlet var teamButtons: [UIButton]!
   @IBOutlet weak var teamLogo: UIImageView!
   @IBOutlet weak var awayTeamUnderlineView: UIView! // Home team on the right, away team on the left
   @IBOutlet weak var homeTeamUnderlineView: UIView!
   
   // Each button is a toggle
   @IBAction func roundButtonActions(_ sender: UIButton) {
      guard let vm = self.viewModel else { return }
      switch sender.tag {
         case 0:
            if sender.isSelected {
               roundButtons[0].isSelected = false
               if let index = vm.selectedPeriods.firstIndex(of: 1) {
                  vm.selectedPeriods.remove(at: index)
               }
            }
            else {
               roundButtons[0].isSelected = true
               vm.selectedPeriods.append(1)
            }
         case 1:
            if sender.isSelected {
               roundButtons[1].isSelected = false
               if let index = vm.selectedPeriods.firstIndex(of: 2) {
                  vm.selectedPeriods.remove(at: index)
               }
            }
            else {
               roundButtons[1].isSelected = true
               vm.selectedPeriods.append(2)
            }
         case 2:
            if sender.isSelected {
               roundButtons[2].isSelected = false
               if let index = vm.selectedPeriods.firstIndex(of: 3) {
                  vm.selectedPeriods.remove(at: index)
               }
            }
            else {
               roundButtons[2].isSelected = true
               vm.selectedPeriods.append(3)
            }
         default:
            if sender.isSelected {
               roundButtons[3].isSelected = false
               if let index = vm.selectedPeriods.firstIndex(of: 4) {
                  vm.selectedPeriods.remove(at: index)
               }
            }
            else {
               roundButtons[3].isSelected = true
               vm.selectedPeriods.append(4)
            }
      }
   }
   @IBAction func shotTypeButtonsAction(_ sender: UIButton) {
      guard let vm = self.viewModel else { return }
      switch sender.tag {
      case 0:
         shotTypeButtons[0].setTitleColor(defaultColors.defaultColor, for: .normal)
         shotTypeButtons[1].setTitleColor(defaultColors.defaultWhiteColor, for: .normal)
         shotTypeButtons[2].setTitleColor(defaultColors.defaultWhiteColor, for: .normal)
         vm.selectedShotType = .FIELD_GOAL
      case 1:
         shotTypeButtons[1].setTitleColor(defaultColors.defaultColor, for: .normal)
         shotTypeButtons[0].setTitleColor(defaultColors.defaultWhiteColor, for: .normal)
         shotTypeButtons[2].setTitleColor(defaultColors.defaultWhiteColor, for: .normal)
         vm.selectedShotType = .THREE_PTR
      default:
         shotTypeButtons[2].setTitleColor(defaultColors.defaultColor, for: .normal)
         shotTypeButtons[0].setTitleColor(defaultColors.defaultWhiteColor, for: .normal)
         shotTypeButtons[1].setTitleColor(defaultColors.defaultWhiteColor, for: .normal)
         vm.selectedShotType = .TOTAL
      }
   }
   @IBAction func teamsButtonAction(_ sender: UIButton) {
      switch sender.tag {
         case 0:
            self.viewModel?.selectedTeam = self.viewModel?.sportData.homeTeam
         default:
            self.viewModel?.selectedTeam = self.viewModel?.sportData.awayTeam
      }
   }
   
   struct defaultColors {
      static let defaultColor: UIColor = #colorLiteral(red: 0.9598677754, green: 0.5958323479, blue: 0.08227530867, alpha: 1)
      static let defaultRedColor: UIColor = #colorLiteral(red: 0.768627451, green: 0.0184048675, blue: 0.1276939213, alpha: 1)
      static let defaultWhiteColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
   }
   
   public var viewModel: basketballViewModel? {
      didSet {
         onViewModelUpdated()
      }
   }
   private var centerCell: teamCollectionViewCell?
   private var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
   private var downloader: Q.httpDownloader = Q.httpDownloader()
   private var currentSelectedTeam: basketballTeam?

   public override func awakeFromNib() {
      super.awakeFromNib()

      let flowLayout = CustomFlowLayout()

      // Since we do not have a File Owner, we need to manually set this here
      collectionView.delegate = self
      collectionView.dataSource = self
      collectionView.collectionViewLayout = flowLayout

      guard let cellViewNib = UINib.fromSdkBundle("teamCollectionViewCell") else { return }
      collectionView.register(cellViewNib, forCellWithReuseIdentifier: "teamCell")
   }
   private func onViewModelUpdated() {
      guard let vm = self.viewModel else { return }
      
      // Set the default shot type. This should match the pre-selection state of our view
      vm.selectedShotType = .FIELD_GOAL
            
      // Listen for changes to the view model
      vm.teamSelected = { t in self.onTeamSelected( t ) }

      // 3-character title for team selection buttons (no more than 3 or it may not show up)
      if let htaName = vm.sportData.homeTeam?.abreviatedName,
         let ataName = vm.sportData.awayTeam?.abreviatedName {
         teamButtons[0].setTitle(String(htaName.prefix(3)), for: .normal)
         teamButtons[1].setTitle(String(ataName.prefix(3)), for: .normal)
      }
      
      // Reset carousel
      selectedIndexPath = IndexPath(row: 0, section: 0)
      
      // Clear selected players, then set a selected team, or home if unset.
      // This will trigger an update
      vm.selectedPlayers.removeAll()
      vm.selectedTeam = (vm.selectedTeam == nil ? vm.sportData.homeTeam : vm.selectedTeam)
   }
   private func onTeamSelected( _ selectedTeam: basketballTeam? ) {
      guard let st = selectedTeam else { return }
      
      if st != currentSelectedTeam {
         currentSelectedTeam = st
         
         homeTeamUnderlineView.isHidden = !st.isHome
         awayTeamUnderlineView.isHidden = st.isHome
         teamButtons[0].setTitleColor(st.isHome ? defaultColors.defaultColor : defaultColors.defaultWhiteColor, for: .normal)
         teamButtons[1].setTitleColor(!st.isHome ? defaultColors.defaultColor : defaultColors.defaultWhiteColor, for: .normal)
         
         // Tell the carousel to reload team info, then move to the previously selected player for that team
         collectionView.reloadData()
         if let vm = self.viewModel {
            var selectedRowIndex: Int? = 0
            if let selectedPlayer = vm.selectedPlayers.first(where: { p in p.team == selectedTeam }) {
               selectedRowIndex = selectedTeam?.players.firstIndex(where: {p in p == selectedPlayer })
               if selectedRowIndex == nil { selectedRowIndex = 0 }
               else { selectedRowIndex! += 1 }
            }
            collectionView.scrollToItem(at: IndexPath(row: selectedRowIndex!, section: 0), at: .centeredHorizontally, animated: false)
         }
         
         // Asynchronously set the team logo
         UIImage.fromUrl(url: st.logoUrl, downloader: downloader, completion:{ image in self.teamLogo.image = image })
      }
   }
}

extension bottomControlPanel: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
   public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      // Player at index zero represents the team.,
      // If no team is selected, assume the home team
      if let vm = self.viewModel {
         if let selectedTeam = (vm.selectedTeam ?? vm.sportData.homeTeam) {
            return selectedTeam.players.count + 1
         }
      }
      return 1 // Team is player zero
   }
   public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "teamCell", for: indexPath) as! teamCollectionViewCell
      
      if let vm = self.viewModel {
         if let selectedTeam = (vm.selectedTeam ?? vm.sportData.homeTeam) {
                  
            // Team is player zero
            if indexPath.row == 0 {
            
               // Asynchronously set the team logo
               UIImage.fromUrl(url: selectedTeam.logoUrl,
                  downloader: downloader,
                  completion:{ image in cell.teamImageView.image = image })
               
               // Set the team name text area
               cell.nameLabel.text = selectedTeam.name
            }
            else {
               let playerIndex = indexPath.row - 1
               
               // Asynchronously set the player logo
               UIImage.fromUrl(url: selectedTeam.players[playerIndex].hsUrl,
                  downloader: downloader,
                  completion:{ image in cell.teamImageView.image = image })
               
               // Set the player name text area
               cell.nameLabel.text = selectedTeam.players[playerIndex].fn
            }
            
            if let teamColor = selectedTeam.colors.first {
               cell.bgView.backgroundColor = UIColor(hexString: teamColor.hexString)
            } else {
               cell.bgView.backgroundColor = defaultColors.defaultWhiteColor
            }
         }
      }
      
      cell.nameLabel.textColor = defaultColors.defaultWhiteColor
      cell.hidesLabel(selectedIndexPath != indexPath)
      
      cell.layoutIfNeeded()
      return cell
   }
   public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
      // TODO: Need a cancel option in Q. I don't want it use Kingfisher here, already using it in Q
      //(cell as? teamCollectionViewCell)?.teamImageView.kf.cancelDownloadTask()
   }
}

extension bottomControlPanel: UIScrollViewDelegate {
   public func scrollViewDidScroll(_ scrollView: UIScrollView) {
      
      let center = CGPoint(x: collectionView.frame.size.width / 2 + scrollView.contentOffset.x, y: collectionView.frame.size.height / 2 + scrollView.contentOffset.y)
      
      if let indexPath = collectionView.indexPathForItem(at: center), centerCell == nil {
         centerCell = collectionView.cellForItem(at: indexPath) as? teamCollectionViewCell
         if indexPath != selectedIndexPath {
            selectedIndexPath = indexPath
         }
         let generator = UIImpactFeedbackGenerator(style: .light)
         generator.impactOccurred()
         centerCell?.hidesLabel(false)
      }
      
      if let cell = centerCell {
         let offsetX = center.x - cell.center.x
         
         if offsetX < -15 || offsetX > 15 {
            cell.hidesLabel(true)
            centerCell = nil
         }
      }
   }
   public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      if !decelerate {
         scrollingFinshed(in: scrollView)
      }
   }
   public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
      scrollingFinshed(in: scrollView)
   }
   public func scrollingFinshed(in scrollView: UIScrollView) {
      let center = CGPoint(x: collectionView.frame.size.width / 2 + scrollView.contentOffset.x, y: collectionView.frame.size.height / 2 + scrollView.contentOffset.y)
               
      if let vm = self.viewModel,
         let selectedTeam = (vm.selectedTeam ?? vm.sportData.homeTeam),
         let indexPath = collectionView.indexPathForItem(at: center) {
         
         // Since we only allow one selected player per team (including the special "team" player),
         // we need to remove the existing selection
         vm.selectedPlayers.removeAll( where: { p in
            p.team == selectedTeam
         })
      
         // If this is not the "team" player
         if indexPath.row > 0 {
            let playerIndex = indexPath.row - 1
            vm.selectedPlayers.append( selectedTeam.players[playerIndex] )
         }
      }
   }
}

class CustomFlowLayout: UICollectionViewFlowLayout {
   var activeDistance: CGFloat = 200
   let zoomFactor: CGFloat = 0.5
   
   override init() {
      super.init()
      
      scrollDirection = .horizontal
      minimumLineSpacing = -40
      let size: CGFloat = 70
      itemSize = CGSize(width: size, height: size)
   }
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   override func prepare() {
      guard let cv = self.collectionView else { fatalError() }
      activeDistance = cv.frame.width / 3
      let horizontalInsets = (cv.frame.width - cv.adjustedContentInset.right - cv.adjustedContentInset.left - itemSize.width) / 2
      sectionInset = UIEdgeInsets(top: 0, left: horizontalInsets, bottom: 0, right: horizontalInsets)
      
      super.prepare()
   }
   override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
      guard let cv = self.collectionView else { return nil }
      
      let rectAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
      let visibleRect = CGRect(origin: cv.contentOffset, size: cv.frame.size)
      
      // Make the cells be zoomed when they reach the center of the screen
      for attributes in rectAttributes  {
         let distance = visibleRect.midX - attributes.center.x
         let height = cv.frame.height
         let normalizedDistance = distance / activeDistance
         let zoom = 1 + (height * 0.012) * (1 - normalizedDistance.magnitude)
         attributes.alpha = 1 - normalizedDistance.magnitude// + 0.2
         let zoomTransform = CGAffineTransform(scaleX: zoom, y: zoom)
         let translateVal = normalizedDistance.magnitude * 10
         let translateTransform = CGAffineTransform(translationX: 0, y: translateVal)
         let combinedTransorm = translateTransform.concatenating(zoomTransform)
         attributes.transform = combinedTransorm
         attributes.zIndex = Int.max - Int(distance.magnitude.rounded())
      }
      
      return rectAttributes
   }
   override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
      guard let cv = collectionView else { return .zero }
      
      // Add some snapping behaviour so that the zoomed cell is always centered
      let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: cv.frame.width, height: cv.frame.height)
      guard let rectAttributes = super.layoutAttributesForElements(in: targetRect) else { return .zero }
      
      var offsetAdjustment = CGFloat.greatestFiniteMagnitude
      let horizontalCenter = proposedContentOffset.x + cv.frame.width / 2
      
      for layoutAttributes in rectAttributes {
         let itemHorizontalCenter = layoutAttributes.center.x
         if (itemHorizontalCenter - horizontalCenter).magnitude < offsetAdjustment.magnitude {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter
         }
      }
      
      return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
   }
   override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
      // Invalidate layout so that every cell get a chance to be zoomed when it reaches the center of the screen
      return true
   }
   override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
      let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
      context.invalidateFlowLayoutDelegateMetrics = newBounds.size != self.collectionView?.bounds.size
      return context
   }
}
