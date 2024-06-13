import UIKit
import Q

// Handy singleton class for managing our experience and AR state
public class experienceWrapper {
   
   // Our sport + experience object:
   // - sport: golf, basketball, etc.
   // - experience: venue, table-top, etc.
   public private(set) var experience: sportExperience? = nil
   // Handle this callback to receive log messages including errors, analytics, and other types of messages.
   // All types of messages from Q, Q_ui, and the experience wrapper will invoke this
   public var logEntryAdded: Q.log.logEntryAddedDelegate?

   // Singleton
   static public private(set) var instance = experienceWrapper()
   private init() {}
   
   // Create and set the experience
   public func createAndSetExperience< T: sportExperience >( type: T.Type, sdkUrl: URL,
      parent: UIViewController?,
      callbackWhenDone: @escaping (T?, arUiViewUpdate) -> () = {def,ault in} ) {
      
      // Don't recreate the same experience we already have
      if let ex = (self.experience as? T), ex.arViewController.arUiConfig.url == sdkUrl.absoluteString {
         let returnValue = arUiViewUpdate(error: .INIT, errorMsg: defaults.experienceAlreadyCreated)
         callbackWhenDone(ex, returnValue)
         return
      }

      // Create our SDK configuration object. This object will take care of downloading and parsing the JSON configuration file.
      // This is an asynchronous call, so we need to handle the callback in order to know when it is finished,
      // and to know whether or not it succeeded. This will happen on a background thread so the main thread will
      // not be blocked.
     arUiViewConfig.create( url: sdkUrl.absoluteString ) { result in
         switch result.error {
            case ERROR.NONE:
               // The config was downloaded, parsed, and validated successfully

               // Create the ar view basketballVenue. Again, this is asynchronous and will happen on BOTH a background thread
               // and main thread as needed, so we need to handle the callback
               Q_ui.arUiViewController.create(type: type, config: result.config as! arUiViewConfig ) { result in
                  switch result.error {
                     case ERROR.NONE:
                        // The experience and all it's internal stuff was created successfully and ready for AR
                        if let controller = result.controller, var experience = controller.sportExperience as? T {

                           // Keep a reference to the experience
                           self.experience = experience

                           // The experience needs a parent
                           experience.parent = parent
                           
                           // Handler for log entries. This includes logs from Q, Q.ui, and this experience wrapper.
                           // The application can optionally handle the `logEntryAdded` callback provided by this class (not Q.log)
                           Q.log.instance.logEntryAdded = self.onLogEntryAdded;
                           
                           // We don't know what thread we are on, but likely a background thread.
                           // Do not continue until this is complete
                           DispatchQueue.main.sync { experience.onInit() }

                           let success = arUiViewUpdate( error: .NONE, errorMsg: "", config: controller.arUiConfig, controller: result.controller )
                           callbackWhenDone( experience, success )
                        }
                     default:
                     let failure = arUiViewUpdate( error: result.error, errorMsg: result.errorMsg, config: result.config )
                        callbackWhenDone( nil, failure )
                  }
               }
            default:
            let failure = arUiViewUpdate( error: result.error, errorMsg: result.errorMsg )
               callbackWhenDone( nil, failure )
         }
      }
   }
   private func onLogEntryAdded(severity: Q.LOG_SEVERITY, message: String, userInfo: [AnyHashable:Any]? ) {
      // Reserving this area for future internal handling and filtering
      
      // Route this log entry to the application, if it is interested.
      if let callback = self.logEntryAdded {
         callback(severity, message, userInfo)
      }
   }
}
