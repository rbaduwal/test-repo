import Foundation

public struct Schedule : Decodable {
   var tournaments: [Tournament]?
}
public struct Tournament : Decodable {
   
   let gid : String?
   let gna : String?
   let st : String?
   let et : String?
   let desc : String?
   let vna : String?
   let ci : String?
   let stt : String?
   let dc : String?
   let lurl : String?
   let zn : String?
   let tz : String?
   let qrealityUrl: String?
   let fops : [fop]?
   
   public func getStartDate() -> Date? {
      if let startDateString = st {
         return getDate(date: startDateString)
      } else {
         return nil
      }
   }
   public func getEndDate() -> Date? {
      if let endDateString = et {
         return getDate(date: endDateString)
      } else {
         return nil
      }
   }
   public func getHoleNumber(index:Int) -> Int? {
      if let id = fops?[index].fid {
         return Int(id)
      } else {
         return nil
      }
   }
   public func getHolePar(index:Int) -> Int? {
      if let par = fops?[index].ft {
         return Int(par)
      } else {
         return nil
      }
   }
   public func getHomeYard(index:Int) -> Int? {
      if let yard = fops?[index].fd {
         return Int(yard)
      } else {
         return nil
      }
   }
}

struct fop : Decodable {
   let fid : String?
   let fna : String?
   let ft : String?
   let fdesc : String?
   let fd : String?
   let lat : String?
   let long : String?
   let fiurl : String?
   let fsurl : String?
   let flurl : String?
   let fcurl : String?
}
