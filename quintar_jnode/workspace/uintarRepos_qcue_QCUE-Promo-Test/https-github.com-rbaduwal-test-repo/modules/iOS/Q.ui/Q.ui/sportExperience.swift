import UIKit
import Q

public protocol sportExperience {

   var geofenceCallback: ((String)->( Bool, String )) {get set}
   var requiredOrientation: ORIENTATION {get set}
   var orientationDefinesArState: Bool { get set }
   var parent: UIViewController? { get set }
   var fop: String? { get set }
   var arViewController: arUiViewController { get }
   var inAr: Bool { get }
   
   init(arViewController: arUiViewController) throws
   
   func createScene() -> qRootEntity
   func destroyScene()
   func onInit()
   func onUninit()
   func onShow(viewController: arUiViewController)
   func onHide(viewController: arUiViewController)
   func onAppSuspend()
   func onAppResume()
   func onFrameUpdated()
   func enterAr(callbackWhenDone: @escaping (arUiViewUpdate) -> ())
   func leaveAr()
   
   static func doesSupportExperience(sport: SPORT, experience: EXPERIENCE) -> Bool
}

public enum ORIENTATION {
   case LANDSCAPE
   case PORTRAIT
   case ANY
}
