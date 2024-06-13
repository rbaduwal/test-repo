public class log {
   
   public private (set) static var instance: log = log()
   
   // If not set, the log will print to the debug console
   public typealias logEntryAddedDelegate = ((LOG_SEVERITY, String, [AnyHashable:Any]?) -> ())
   public var logEntryAdded: logEntryAddedDelegate?
   
   private let url: String
   
   public init() {
      url = ""
   }
   public func push(_ s: LOG_SEVERITY, msg: String, userInfo: [AnyHashable:Any]? = nil) {
      if let handler = logEntryAdded {
         handler(s, msg, userInfo)
      } else {
         print( "\(s): \(msg)" )
      }
   }
}

public enum LOG_SEVERITY {
   case INFO
   case WARNING
   case ERROR
   case ANALYTICS
   case DEBUG
}
