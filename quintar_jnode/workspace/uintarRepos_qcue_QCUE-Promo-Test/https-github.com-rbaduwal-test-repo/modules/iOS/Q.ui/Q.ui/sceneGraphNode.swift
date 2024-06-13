import Foundation

// TODO: Is this really necessary?
class sceneGraphNode: qEntity, qHasCollision {
   
   func hide() {
      isEnabled = false
   }
   func show() {
      isEnabled = true
   }
}
