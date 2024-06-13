public protocol sportData {
   
   var config: sportDataConfig { get }
   var isDataSynced: Bool { get }
   
   init( config: sportDataConfig ) throws
   
   // There should be exactly one call to stopLive() for every call to startLive()
   func startLive()
   func stopLive()
   
   // TODO: This may or may not be used in the future
   func queryArchive( query: String )
   
   // Post a notification. Usually called from an internal data class
   func postNotification(name: String, object: Any?, userInfo: [AnyHashable:Any]?, canDefer: Bool)
   
   // An event for when the configuration is updated
   var configUpdated: ((sportDataConfig)->())? { get set }
   
   // Event for when data is synchronized
   var liveSynced: ((sportData)->())? { get set }
   
   // Thread safe queue for read/writes
   var threadSafety: DispatchQueue { get }
}
