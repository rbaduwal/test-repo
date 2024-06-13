import Q

internal class golfTeeBoxPlayerCard : sceneGraphNode {
   var smallPlayerCard: golfSmallTeeBoxPlayerCard? = nil
   var isLiveMode = false
   var viewModel: golfTeeboxViewModel
   
   required init( model: golfTeeboxViewModel,
      arView: qARView?,
      isLiveMode: Bool,
      heightMultipler: Int) {
      
      self.viewModel = model
      self.isLiveMode = isLiveMode // TODO: Shouldn't this be the same enum used in golfGroup?
      
      super.init()
      
      smallPlayerCard = golfSmallTeeBoxPlayerCard(model: model, arView: arView, heightMultipler: heightMultipler)
      if let smallPlayerCard = smallPlayerCard {
         self.addChild(smallPlayerCard)
      }
      self.hide()
   }   
   required init?(coder: NSCoder) {
      fatalError("Not implemented")
   }
   required override init() {
      fatalError("init() has not been implemented")
   }
   
   override func show() {
      smallPlayerCard?.show()
      super.show()
   }
   override func hide() {
      smallPlayerCard?.hide()
      super.hide()
   }
   func applyCorrectionMatrix() {
      smallPlayerCard?.applyCorrectionMatrix()
   }
   func setHeightMultiplier(heightMultiplier:Int) {
      smallPlayerCard?.heightMultipler = heightMultiplier
   }
}
