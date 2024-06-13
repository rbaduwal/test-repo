import Foundation

extension player {

   public var nameLastCommaFirstInitial: String {
      if self.fn != "" {
         if self.sn != "" {
            return "\(self.sn), \((self.fn.first?.description ?? "").uppercased())"
         } else {
            return self.fn
         }
      } else {
         if self.sn != "" {
            return self.sn
         } else {
            return String(format: "Player %d", self.pid)
         }
      }
   }
   public var nameFirstInitialDotLast: String {
      if self.fn != "" {
         if self.sn != "" {
            return "\((self.fn.first?.description ?? "").uppercased()). \(self.sn)"
         } else {
            return self.fn
         }
      } else {
         if self.sn != "" {
            return self.sn
         } else {
            return String(format: "Player %d", self.pid)
         }
      }
   }
}
