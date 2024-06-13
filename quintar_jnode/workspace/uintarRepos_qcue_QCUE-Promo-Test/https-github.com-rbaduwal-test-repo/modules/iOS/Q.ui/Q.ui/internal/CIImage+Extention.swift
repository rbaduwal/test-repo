import UIKit

internal extension CIImage {
   func compress(compressionQuality:Float) -> Data? {
      let option =  [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : compressionQuality]
      let ciContext = CIContext()
      let mutableData = ciContext.jpegRepresentation(of: self,
                                                     colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: option )
      return mutableData
   }
   
   func scale(scaleFactor:Float) -> CIImage{
      let aspectRatio = 1.0 // maintain aspect ratio
      let resizeFilter = CIFilter(name: "CILanczosScaleTransform")
      resizeFilter?.setValue(self, forKey: kCIInputImageKey)
      resizeFilter?.setValue(scaleFactor, forKey: kCIInputScaleKey)
      resizeFilter?.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
      return  (resizeFilter?.outputImage!)!
      
   }
   
   func grayScale() -> CIImage{
      let grayFilter = CIFilter(name: "CIPhotoEffectMono")
      grayFilter?.setValue(self, forKey: kCIInputImageKey)
      
      return (grayFilter?.outputImage!)!
   }
}
