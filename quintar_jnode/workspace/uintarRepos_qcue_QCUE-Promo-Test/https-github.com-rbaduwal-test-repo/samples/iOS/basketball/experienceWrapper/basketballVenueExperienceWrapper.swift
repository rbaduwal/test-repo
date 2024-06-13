import UIKit
import Q_ui
import Q

public class basketballVenueExperienceWrapper : Q_ui.basketballVenue {

   public private(set) var screenView: experienceView?
   
   private var drawCounter: UInt64 = 0;
   private var trackingBegins: Bool = false
   private var trackingFailureCount = 0
   private var timeWhenEnteringBackgroundState: Date = Date.now
   
   // Ensure these computed properties are only called from the main thread
   public var enableDebugLabel: Bool {
      get { return screenView?.enableDebugLabel ?? false }
      set { screenView?.enableDebugLabel = newValue }
   }
   public var enableAutoExposure: Bool = true {
      didSet { screenView?.enableAutoExposure(enableAutoExposure) }
   }
   public var defaultExposureBias: Float? {
      get { return screenView?.defaultExposureBias }
      set { screenView?.defaultExposureBias = newValue }
   }

   public override func onInit() {
      super.onInit()
      
      guard let viewNib = UINib.fromSdkBundle("experienceView") else { return }
      self.screenView = viewNib.instantiate(withOwner: nil, options: nil).first as? experienceView

      // Set our venue object as the view model
      self.screenView?.bottomDashboardView?.viewModel = self
      
      // Assign handlers for both the big basketball button and the text area
      self.screenView?.tapToBeginButton.addTarget(self, action: #selector(tapToBeginAction), for: .touchUpInside)
      self.screenView?.bottomDashboardView.buttonPressed = { self.tapToBeginAction() }
      
      // Defaults
      self.screenView?.enableDebugLabel = false
      self.screenView?.enableAutoExposure(enableAutoExposure)
              
      // Set our 2D experience for the SDK, since it only provides the 3D stuff
      self.arViewController.screenView = self.screenView
      
      // Here's where you can add some geo-fencing logic
      self.geofenceCallback = { fop in
         return (true, "")
      }
      
      // This is a good spot to turn on microphone access, if needed
      self.arViewController.arUiConfig.microphoneEnabled = false
      
      // Enabling test mode is ONLY for non-production builds (or you can hide it behind an Easter egg).
      // Test mode allows us to:
      //  - use test images on a real connect server
      //  - show outlines
      // You can pass in an empty array [] to disable all tests.
      // Tests also depend on appropriate values in the config files.
      self.enableTestModes( [.OUTLINES, .TEST_IMAGE] )
      
      // Hook into the draw callback
      self.arViewController.onDrawBegin = { self.onDrawBegin() };
   }
   public override func onShow( viewController: arUiViewController ) {
      super.onShow(viewController: viewController)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
         if self.trackingBegins {
            self.screenView?.bottomDashboardView.beginAnimate()
         }
      }
   }
   public override func onHide( viewController: arUiViewController ) {
      super.onHide(viewController: viewController)
      self.screenView?.bottomDashboardView.centerButton?.layer.removeAllAnimations()
   }
   public override func onTrackingUpdated(trackingStatus: trackingUpdate) {
      super.onTrackingUpdated(trackingStatus: trackingStatus)
      
      DispatchQueue.main.async {
         self.trackingBegins = false
         
         switch trackingStatus.error {
            case .NONE:
               self.screenView?.bottomDashboardView.endAnimate( true )
            default:
               self.trackingFailureCount = self.trackingFailureCount + 1
               if self.trackingFailureCount > self.experienceConfig?.maxTrackingFailure ?? 3 {
                  self.resetTrackingOnFailure()
               }
         }
      }
   }
   
   @objc private func tapToBeginAction() {
      if let tracker = arViewController.tracker {
         if !tracker.isTracking {
         
            // Update UI
            trackingBegins = true
            self.screenView?.bottomDashboardView.beginAnimate()
            screenView?.tapBeginView.isHidden = true
               
            // Start tracking
            startTracking(useLocationServices: false)
         }
      }
   }
   @objc func appMovedToBackground() {
      timeWhenEnteringBackgroundState = Date.now
   }
   @objc func appMovedToForeground() {
      if (Date.now.timeIntervalSince1970 - timeWhenEnteringBackgroundState.timeIntervalSince1970) > 5 {
        self.resetTrackingOnFailure()
     }
  }
   private func onDrawBegin() {
      self.drawCounter += 1;
      
      if let isHidden = screenView?.debugLogLabel.isHidden,
         isHidden == false,
         drawCounter % 10 == 0 {
         
         screenView?.updateDebugLabel();
      }
   }
   private func resetTrackingOnFailure() {
      self.screenView?.bottomDashboardView.endAnimate( false )
      self.screenView?.tapBeginView.isHidden = false
      self.stopTracking()
   }
   private func addObservers() {
      self.removeObservers()
      
      NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
   }
   private func removeObservers() {
      NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
      NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
   }
}
