@file:Suppress("ArrayInDataClass")

package ai.quintar.q.connect

import ai.quintar.q.utility.ERROR
import java.io.Serializable

@Suppress("ClassName") data class trackingUpdate(var error: ERROR,
   var errorMsg: String,
   var url: String,
   var transform: List<Double>?,
   @Transient var sceneIntrinsic: sceneIntrinsic,
   var timestamp: Long,
   var confidenceValue: Double?,
   var viewPosition: List<Float>?,
   var viewDirection: List<Float>?,
   var errorBody: String?) : Serializable