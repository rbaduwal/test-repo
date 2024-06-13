import Foundation

class golfGreenPlayerCard : sceneGraphNode {
   public var viewModel: golfGreenViewModel
   
   private var smallPlayerCard: golfSmallGreenPlayerCard? = nil
   private var bigPlayerCard: golfBigGreenPlayerCard? = nil
   private var golfGreenPlayerCardBaseEntity: golfGreenPlayerCardBaseEntity? = nil
   
   required init( model: golfGreenViewModel,
                  arView: qARView?,
                  heightMultiplier: Int,
                  golfGreenPlayerCardBaseEntity : golfGreenPlayerCardBaseEntity) {
      self.viewModel = model
      super.init()
      
      // Observe view model changes
      self.viewModel.distanceToHoleChanged.add(self.onDistanceToHoleChanged, id: "golfGreenPlayerCard")
      //self.viewModel.distanceToHoleChanged += ("golfGreenPlayerCard", self.onDistanceToHoleChanged) // TODO: Why does this fail?
      
      smallPlayerCard = golfSmallGreenPlayerCard(model: model, arView: arView, heightMultipler: heightMultiplier)
      
      bigPlayerCard = golfBigGreenPlayerCard(model: model, arView: arView, heightMultipler: heightMultiplier)
      if let bigPlayerCard = bigPlayerCard {
         self.addChild(bigPlayerCard)
      }
      
      self.golfGreenPlayerCardBaseEntity = golfGreenPlayerCardBaseEntity
      
      self.hide()
   }
   
   required init?(coder: NSCoder) {
      fatalError("Not implemented")
   }
   override required init() {
      fatalError("init() has not been implemented")
   }
   
   func setHeightMultiplier(heightMultiplier: Int) {
      bigPlayerCard?.heightMultipler = heightMultiplier
      applyCorrectionMatrix()
   }
   func applyCorrectionMatrix() {
      bigPlayerCard?.applyCorrectionMatrix();
   }
   
   fileprivate func pickCardBasedDistanceToHole() {
      if self.viewModel.distanceToHole == 0 {
         bigPlayerCard?.hide()
         if let smallPlayerCard = smallPlayerCard {
            self.golfGreenPlayerCardBaseEntity?.addHoleOutCard(holeOutCard: smallPlayerCard)
         }
      } else {
         if let smallPlayerCard = smallPlayerCard {
            self.golfGreenPlayerCardBaseEntity?.hideHoleoutCard(holeOutCard: smallPlayerCard)
         }
         bigPlayerCard?.show()
      }
   }
   func onDistanceToHoleChanged(distanceToHole: Float) {
      pickCardBasedDistanceToHole()
   }
   override func show() {
      pickCardBasedDistanceToHole()
      super.show()
   }
   override func hide() {
      bigPlayerCard?.hide()
      if let smallPlayerCard = smallPlayerCard {
         self.golfGreenPlayerCardBaseEntity?.hideHoleoutCard(holeOutCard: smallPlayerCard)
      }
      super.hide()
   }
}
