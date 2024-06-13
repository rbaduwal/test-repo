public extension String {
   var toDate: Date {
      get {
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
         if let date = dateFormatter.date(from: self) {
             return date
         } else {
             dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
             if let date = dateFormatter.date(from: self) {
                 return date
             } else {
                 return Date()
             }
         }
      }
   }
   func contains(word : String) -> Bool {
       return self.range(of: "\\b\(word)\\b", options: [.regularExpression,.caseInsensitive]) != nil
   }
}
