public protocol config {
   
   var timeout: Int {get set}
   var downloader: downloader?{get set}
   var url: String {get}
   var data: [String:Any] {get}
   var testData: [String:Any] {get}

   // Events
   typealias ConfigUpdated = ((configUpdate)->())
   var updated: ConfigUpdated? {get set}
}

public struct configUpdate {
   
   public let error: ERROR
   public let errorMsg: String
   public let url: String
   public let oldJson: [String:Any]?
   public let config: config?
   
   public init( error:ERROR,
                errorMsg: String,
                url: String,
                oldJson: [String:Any]?,
                config: config? ) {
      
      self.error = error
      self.errorMsg = errorMsg
      self.url = url
      self.oldJson = oldJson
      self.config = config
   }
}
