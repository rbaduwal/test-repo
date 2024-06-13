import Foundation

// UInt32 colors in ARGB order, little-endian
public class color {
   public var hexString: String {
      get {
         let rgba:Int = Int(a)<<24 | Int(r)<<16 | Int(g)<<8 | Int(b)<<0
         return String(format:"#%08x", rgba)
      }
      set {
         self.uintValue = color.from(hexString: newValue)
      }
   }
   public var hex: UInt32 {
      get { return UInt32(uintValue) }
      set { self.uintValue = UInt64(newValue) }
   }
   public var a: UInt8 {
      get { return UInt8(uintValue >> 24 & mask) }
      set {
         uintValue &= (0xFFFFFFFF >> 8)
         uintValue |= (UInt64(newValue)<<24) }
   }
   public var r:  UInt8 { get { return UInt8((uintValue >> 16) & mask) } }
   public var g:  UInt8 { get { return UInt8(uintValue >> 8  & mask) } }
   public var b:  UInt8 { get { return UInt8(uintValue >> 0  & mask) } }
   public var af: Float {
      get { return Float(a) / 255.0 }
      set { a = UInt8(newValue * 255.0) }
   }
   public var rf: Float { get { return Float(r) / 255.0 } }
   public var gf: Float { get { return Float(g) / 255.0 } }
   public var bf: Float { get { return Float(b) / 255.0 } }
   public private(set) var uintValue: UInt64
   
   private let mask: UInt64 = 0x000000FF
   
   public init(hexString: String, alpha: Float = 1.0) {
      self.uintValue = color.from(hexString: hexString)
      self.af = alpha
   }
   
   static public func from( hexString: String ) -> UInt64 {
      let s = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
      let scanner = Scanner(string: s)
      if s.hasPrefix("#") {
         scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
      }
      var returnValue: UInt64 = 0
      scanner.scanHexInt64(&returnValue)
      return returnValue
   }
}

