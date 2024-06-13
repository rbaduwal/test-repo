import Foundation
import Q

public struct arUiViewUpdate {
   public let error: ERROR
   public let errorMsg: String
   public let config: arUiViewConfig?
   public let controller: arUiViewController?
   
   public init( error: ERROR, errorMsg: String, config: arUiViewConfig? = nil, controller: arUiViewController? = nil) {
      self.error = error
      self.errorMsg = errorMsg
      self.config = config
      self.controller = controller
   }
}
