//
//  UIImage+Extension.swift
//  pgatourpoc
//
//  Created by Arun Induchoodan on 11/02/21.
//

import UIKit

extension UIImage{
    
    func getSizeInPixels() -> (width:Int,height:Int){
        let height = Int(self.size.height * self.scale)
        let width = Int(self.size.width * self.scale)
        return (width,height)
    }
    
    func getThumbnail() -> UIImage? {
        
        guard let imageData = self.pngData() else { return nil }
        
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 300] as CFDictionary
        
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        
        return UIImage(cgImage: imageReference)
        
    }
}


