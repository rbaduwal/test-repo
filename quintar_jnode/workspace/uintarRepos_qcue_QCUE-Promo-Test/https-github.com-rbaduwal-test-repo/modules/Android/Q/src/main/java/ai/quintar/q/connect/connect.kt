package ai.quintar.q.connect

import ai.quintar.q.config.configUpdate
import ai.quintar.q.config.connectConfig
import ai.quintar.q.utility.ERROR
import ai.quintar.q.utility.constants
import ai.quintar.q.utility.httpHelper
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.*
import kotlin.concurrent.timer

@Suppress("ClassName")
class connect(config: connectConfig) {
   private var connectConfig: connectConfig = config
   private var isRegistrationInProgress: Boolean = false
   private var trackingTimer: Timer? = null
   private var getSceneIntrinsic: (() -> sceneIntrinsic?)? = null
   private var trackingUpdated: ((trackingUpdate) -> Unit)? = null
   var viewPosition: List<Float>? = listOf(0f, 0f, 0f)
      private set
   var viewDirection: List<Float>? = listOf(0f, 0f, 0f)
      private set
   var trackingTimeInterval = constants.REGISTRATION_DELAY
   var isReadyForTracking = false
   var enableRegistration = true

   private fun doRegistration() {
      CoroutineScope(Dispatchers.IO).launch(Dispatchers.IO) {
         if (isRegistrationInProgress) {
            return@launch
         }
         isRegistrationInProgress = true
         getSceneIntrinsic?.let { getIntrinsic ->
            getIntrinsic()?.let { sceneIntrinsic ->
               connectConfig.connectConfigData?.fops?.get(0)?.apiEntrypointUrl.let { url ->
                  connectConfig.connectConfigData?.fops?.get(0)?.registrationDelay.let {
                     trackingTimeInterval = it as Int
                  }
                  httpHelper.register(url + constants.SEPARATOR + connectConfig
                     .connectConfigData?.lid
                     + constants.SEPARATOR+constants.CONNECT + constants.SEPARATOR
                     + connectConfig.connectConfigData?.fops?.get(0)?.id, sceneIntrinsic) {
                        trackingUpdateValues ->
                     trackingUpdated?.let { trackingUpdate ->
                        if (trackingUpdateValues.error == ERROR.NONE) {
                           if(trackingUpdateValues.viewPosition?.size==3) {
                              viewPosition = trackingUpdateValues.viewPosition
                           }
                           if(trackingUpdateValues.viewDirection?.size==3) {
                              viewDirection = trackingUpdateValues.viewDirection
                           }
                        }
                        trackingUpdate(trackingUpdateValues)
                     }
                  }
               }
            }
         }
         isRegistrationInProgress = false
      }
   }

   fun startTracking(
      sceneIntrinsicCallback: (() -> sceneIntrinsic?),
      onTrackingUpdated: (trackingUpdate) -> Unit
   ) {
      this.getSceneIntrinsic = sceneIntrinsicCallback
      this.trackingUpdated = onTrackingUpdated
      startTrackingTimer()
   }

   fun stopTracking() {
      this.trackingUpdated = null
      stopTrackingTimer()
   }

   private fun startTrackingTimer() {
      stopTrackingTimer()
      // TO-DO Remove the hardcoded locationId
      trackingTimer = timer(
         "Tracking",
         false,
         0,
         trackingTimeInterval.toLong() * 1000) {
         if (isReadyForTracking && !enableRegistration) {
            doRegistration()
         }
      }
   }

   private fun stopTrackingTimer() {
      if (trackingTimer != null) {
         trackingTimer?.cancel()
         trackingTimer = null
      }
   }

   fun isReadyForTracking(isReady_ : Boolean) {
      isReadyForTracking = isReady_
   }
   fun enableRegistration(enabled: Boolean) {
      enableRegistration = enabled
   }
}