import simd

public class utility {
   public static func array2vec<fpTypeIn, fpTypeOut>( _ points: [fpTypeIn], _ index: Int = 0 ) -> SIMD3<fpTypeOut>
      where fpTypeIn: BinaryFloatingPoint, fpTypeOut: BinaryFloatingPoint {
      
      let numVectors = points.count/3 // This will drop any last incomplete triplet, if any
      if numVectors >= 1 {
         return SIMD3<fpTypeOut>(
            fpTypeOut(points[ index                  ]),
            fpTypeOut(points[ index +    numVectors  ]),
            fpTypeOut(points[ index + (2*numVectors) ]) )
      } else {
         return SIMD3<fpTypeOut>()
      }
   }
   public static func array2vec<fpTypeIn, fpTypeOut>( _ points: [fpTypeIn] ) -> [SIMD3<fpTypeOut>]
      where fpTypeIn: BinaryFloatingPoint, fpTypeOut: BinaryFloatingPoint {
      
      var returnValue = [SIMD3<fpTypeOut>]()
      let numVectors = points.count/3 // This will drop any last incomplete triplet, if any
      for count in 0 ..< numVectors {
         returnValue.append(SIMD3<fpTypeOut>(
            fpTypeOut(points[ count                  ]),
            fpTypeOut(points[ count +    numVectors  ]),
            fpTypeOut(points[ count + (2*numVectors) ])
         ))
      }
      return returnValue
   }
}
