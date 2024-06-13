@file:Suppress("ArrayInDataClass")

package ai.quintar.q.connect

import org.json.JSONArray
import org.json.JSONObject
import java.io.Serializable

@Suppress("ClassName") data class sceneIntrinsic(var cameraTransform: DoubleArray,
   var cameraIntrinsics: DoubleArray,
   var lat: Double,
   var lon: Double,
   var altitude: Double,
   var latlonAccuracy: Double,
   var altitudeAccuracy: Double,
   var compass: DoubleArray,
   var gravity: DoubleArray,
   var image: ByteArray,
   var imageWidth: Int,
   var imageHeight: Int,
   var timeStamp: Long,
   var misc: String = "",
   var locationId: String,
   var deviceName: String,
   var deviceType: String,
   var headingAccuracy: Double,
   var currentExposureBias: Float,
   var isDeviceReadyWithTracking: Boolean,
   var appInstanceId : String): Serializable {
   fun toServerFormat(): String {
      val serverFormat = JSONObject()
      serverFormat.put("altitude", altitude)
      serverFormat.put("altitudeAccuracy", altitudeAccuracy)
      serverFormat.put("lon", lon)
      serverFormat.put("lat", lat)
      serverFormat.put("latlonAccuracy", latlonAccuracy)
      serverFormat.put("cam_intrinsics", JSONArray(cameraIntrinsics))
      serverFormat.put("cam_extrinsics", JSONArray(cameraTransform))
      serverFormat.put("gravity", JSONArray(gravity))
      serverFormat.put("magnetic_field", JSONArray(compass))
      serverFormat.put("imgWidth", imageWidth)
      serverFormat.put("imgHeight", imageHeight)
      serverFormat.put("misc", misc)
      serverFormat.put("epochSecs", timeStamp)
      serverFormat.put("deviceType", deviceType)
      serverFormat.put("deviceName", deviceName)
      serverFormat.put("headingAccuracy", headingAccuracy)
      serverFormat.put("currentExposureBias", currentExposureBias)
      serverFormat.put("isDeviceReadyWithTracking", isDeviceReadyWithTracking)
      serverFormat.put("app-instance-id", appInstanceId)
      return serverFormat.toString()
   }
}