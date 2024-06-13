import Foundation
@_implementationOnly import zfp

internal class Zfp {

   public enum ZfpError : Error {
      case DecodeError(String)
   }
      
   public static func decode( _ encodedByteArray: inout Array<UInt8>, _ size: Int ) throws -> Array<Double>? {
      
      // Create a stream
      let zfp = zfp_stream_open(nil) // zfp_stream * zfp
      
      // Associate bit stream with allocated buffer
      var stream: OpaquePointer? = nil
      encodedByteArray.withUnsafeMutableBytes() { rawBuffer in
         stream = stream_open( rawBuffer.baseAddress, size ) // bitstream * stream
      }
      zfp_stream_set_bit_stream( zfp, stream );
      
      // Read the header
      let field = zfp_field_alloc(); // zfp_field * field
      zfp_read_header( zfp, field, ZFP_HEADER_FULL );
      
      // Allocate output
      var returnValue = Array<Double>.init(repeating: 0.0, count: field!.pointee.nx)
      returnValue.withUnsafeMutableBytes() { rawBuffer in
         zfp_field_set_pointer( field, rawBuffer.baseAddress );
      }
      //let resultBuffer = UnsafeMutablePointer<Double>.allocate(capacity: field!.pointee.nx)
      
      
      // Decompress the array
      if zfp_decompress( zfp, field ) == 0 {
         throw ZfpError.DecodeError( "zfp decompression failed" );
      }
      
      // Clean up
      zfp_field_free( field );
      zfp_stream_close( zfp );
      stream_close( stream );
      
      return returnValue
   }
}
