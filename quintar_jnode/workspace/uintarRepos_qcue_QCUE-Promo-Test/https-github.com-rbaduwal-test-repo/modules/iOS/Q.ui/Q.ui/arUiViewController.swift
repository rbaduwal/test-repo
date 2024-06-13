import UIKit
import ARKit
import Q

public class arUiViewController: UIViewController {

   // Render callbacks - do NOT perform anything time consuming here or badness will ensue.
   // TODO: actually call these
   public var onDrawBegin: (()->())? = nil
   public var onDrawEnd: (()->())? = nil
   
   public var screenView: UIView? = nil
   public var arView: qARView {
      // Implementing this as a computed property because the actual arView is an internal class that extends ARView,
      // but this causes an objective-C issue (namely that objective-C doesn't support realitykit) when importing this
      // framework in other applications
      get { return internalArView as qARView }
   }
   public private(set) var arUiConfig: arUiViewConfig
   public private(set) var tracker: connect? = nil
   public private(set) var sportData: sportData? = nil
   public private(set) var sportExperience: sportExperience?
   private var isArRunning = false
   private var internalArView = qARView()
   
   // UIViewController implementation
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   deinit {
      // Let the experience provide us our realitykit scene
      sportData?.stopLive()
      sportExperience?.destroyScene()
   }
   public override func loadView() {
      // Make our ARView the root UIView
      setupARView()
      // Let the experience provide us our scene graph
      if let scene = sportExperience?.createScene() {
         // Add the scene, disabled for now
         scene.isEnabled = false
         self.arView.scene.anchors.append(scene)
      }
      
      // Add the 2D stuff here
      if let sv = screenView {
         sv.frame = self.view.bounds
         self.view.addSubview( sv )
      }
   }
   func setupARView(){
      /* After making ARView as the root view we were facing touch issues in the 2D UI. After comparing with the previous implementation it was found that by adding the ARView as a subview to the root view, the touch issues are getting solved  */
      self.view = UIView()
      self.view.addSubview(internalArView)
      let screenSize: CGRect = UIScreen.main.bounds
      internalArView.frame =  CGRect(x: 0, y: 0, width: screenSize.width, height:  screenSize.height)
   }
   
   public override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear( animated )
      
      UIApplication.shared.isIdleTimerDisabled = true
      
      if !isArRunning {
         self.internalArView.start(enableMicrophone: arUiConfig.microphoneEnabled)
         isArRunning = true
      }
      
      self.sportExperience?.onShow(viewController: self)
   }
   public override func viewWillDisappear(_ animated: Bool) {
      // TODO: have a timer here and pause AR, as well as other clean up items, after a timeout
      //self.internalArView.session.pause()
      
      super.viewWillDisappear(animated)
      
      self.sportExperience?.onHide(viewController: self)
   }
   public override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      UIApplication.shared.isIdleTimerDisabled = false
   }
   public static func create< T: sportExperience >( type: T.Type,
      config: arUiViewConfig,
      callbackWhenDone: @escaping (arUiViewUpdate)->() ) {
      
      // This section must be initialized on the main thread.
      // The constructor is guaranteed to succeeed.
      var aruvc: arUiViewController? = nil
      if !Thread.isMainThread {
         DispatchQueue.main.sync {
            aruvc = arUiViewController(config: config)
         }
      } else {
         aruvc = arUiViewController(config: config)
      }
      let _self = aruvc!
      
      // The remainder should happen on a background thread
      DispatchQueue.global(qos: .background).async {
         do {
            // Validate experience
            guard let experienceType = _self.arUiConfig.experience else {
               let viewUpdate = arUiViewUpdate(error: .INIT, errorMsg: defaults.unknownExperienceType, config: config, controller: nil)
               callbackWhenDone(viewUpdate)
               return
            }
            
            // Validate experience is supported
            guard T.doesSupportExperience(sport: _self.arUiConfig.sport, experience: experienceType) else {
               let viewUpdate = arUiViewUpdate(error: .INIT, errorMsg: "\(defaults.sportExperienceType) \(type) \(defaults.doesNotSupport) \(_self.arUiConfig.sport) and \(experienceType)", config: config, controller: nil)
               callbackWhenDone(viewUpdate)
               return
            }
            
            // Create sportData
            if let sportDataConfig = _self.arUiConfig.sportDataConfig {
               _self.sportData = try createSportData(sport: _self.arUiConfig.sport, config: sportDataConfig)
               _self.sportData?.startLive()
            }
         
            // Create connect
            if let connectConfig = _self.arUiConfig.connectConfig {
               _self.tracker = connect(config:connectConfig)
            }
            
            // Create sport+experience controller
            _self.sportExperience = try T(arViewController: _self)
            
            let viewUpdate = arUiViewUpdate(error: .NONE, errorMsg: "", config: _self.arUiConfig, controller: _self)
            callbackWhenDone(viewUpdate)
         
         } catch ( let e as errorWithMessage) {
            let viewUpdate = arUiViewUpdate(error: .INIT, errorMsg: e.localizedDescription, config: config, controller: nil)
            callbackWhenDone(viewUpdate)
            return
         } catch ( let e ) {
            let viewUpdate = arUiViewUpdate(error: .INIT, errorMsg: "\(e)", config: config, controller: nil)
            callbackWhenDone(viewUpdate)
            return
         }
      }
   }
   public func destroy() {
      internalArView.removeFromSuperview()
      tracker?.stopTracking()
   }
   public func showArDebugInfo(show: Bool) {
      arView.showDebugInfo(show: show)
   }
   
   internal static func createSportData( sport: SPORT, config: sportDataConfig ) throws -> sportData {
      switch sport {
         case .GOLF:
            return try golfData(config: config)
         case .BASKETBALL:
            return try basketballData(config: config)
         default:
            throw errorWithMessage("No support for sport \(sport)")
      }
   }
   private init( config: arUiViewConfig ) {
      self.arUiConfig = config
      
      super.init(nibName: nil, bundle: nil)
      
      // This presents the 2D elements in fullscreen
      //   https://stackoverflow.com/questions/56435510/presenting-modal-in-ios-13-fullscreen
      modalPresentationStyle = .fullScreen
      
      // This is keeps the ARView from being swiped away. The view should be removed another way, such as rotating out of landscape mode
      //   https://stackoverflow.com/questions/56459329/disable-the-interactive-dismissal-of-presented-view-controller
      isModalInPresentation = true
      
      // Configure and add our built-in ARView to the pass-through window
      internalArView.cameraMode = qARView.CameraMode.ar
      internalArView.renderOptions = [.disableAREnvironmentLighting,.disableMotionBlur,
                                      .disableDepthOfField]
      internalArView.contentScaleFactor = 1.0
      internalArView.automaticallyConfigureSession = false
      internalArView.enableAntialiasing( true )
   }
}
