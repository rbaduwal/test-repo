package ai.quintar.q.ui

import ai.quintar.q.connect.connect
import ai.quintar.q.ui.basketball.basketballVenue
import ai.quintar.q.ui.controller.sportsExperienceController
import ai.quintar.q.utility.EXPERIENCE
import ai.quintar.q.utility.SPORT
import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.viro.core.*
import java.lang.ref.WeakReference

@Suppress("ClassName")
class arUiViewController(
   config: arUiViewConfig, private var activity: AppCompatActivity
) : Fragment() {
   var arView: ViroViewARCore? = null
      private set
   var arUiConfig: arUiViewConfig = config
   var arLayer: FrameLayout? = null
   private var experienceview: View? = null
   var experienceLayer: FrameLayout? = null
   var sportsExperienceController: sportsExperienceController? = null
      private set
   var tracker: connect? = null
      private set
   var mScene: ARScene? = null
      private set
   var arSceneListener : ARSceneListener? = null

   init {
      arUiConfig.experience?.let { experience ->
         arUiConfig.sport?.let { sport ->
            createSportExperienceController(sport, experience, activity)
         }
      }

      val connectConfig = arUiConfig.connectConfig
      tracker = connectConfig?.let { connect(it) }
   }

   override fun onCreateView(
      inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
   ): View? {
      val view = inflater.inflate(R.layout.ar_ui_view_layout, container, false)
      arLayer = view.findViewById(R.id.mainview)
      experienceLayer = view.findViewById(R.id.overlayview)
      arView = ViroViewARCore(context as Activity, object : ViroViewARCore.StartupListener {
         override fun onSuccess() {
            mScene = ARScene()
            arSceneListener = ARSceneListener(context as Activity)
            mScene?.setListener(arSceneListener)
            mScene?.rootNode?.addLight(AmbientLight(Color.WHITE.toLong(), 1000f))
            arView?.setCameraRotation(1)
            //setOptimumCameraConfiguration()
            arView?.isCameraAutoFocusEnabled = false
            arView?.scene = mScene
            sportsExperienceController?.initialize(context as AppCompatActivity)
         }

         override fun onFailure(error: ViroViewARCore.StartupError, errorMessage: String) {
            if (arUiConfig.arConfig?.getArUIPermissionErrorMessage == null) {
               Toast.makeText(
                  context, arUiConfig.arConfig?.getArUIPermissionErrorMessage, Toast.LENGTH_LONG
               ).show()
            } else {
               Toast.makeText(
                  context, R.string.camera_permission_error, Toast.LENGTH_LONG
               ).show()
            }
         }
      })
      arLayer?.addView(arView)
      experienceview?.let {
         if (experienceLayer?.getChildAt(0) == null) {
            experienceLayer?.addView(experienceview)
            experienceLayer?.bringToFront()
         }
      }
      return view
   }

   fun enableTestMode(enable: Boolean) {
      sportsExperienceController?.enableTestMode(enable)
   }

   fun showOutline(enable: Boolean) {
      sportsExperienceController?.showOutline(enable)
   }
   fun storeUUID(uuid: String) {
      sportsExperienceController?.storeUUID(uuid)
   }
   private fun setOptimumCameraConfiguration() {
      arView?.cameraConfig?.let { cameraConfig ->
         var optimumCameraConfig: CameraConfigValues? = null

         // Check for a camera config with 60 FPS and resolution >= 1920
         for (item in cameraConfig) {
            if (item.fps == 60) {
               if (item.width >= 1920) {
                  optimumCameraConfig = item
                  break
               }
            }
         }

         // If no camera config with 60 FPS and resolution >= 1920 found
         // then take the highest camera resolution with FPS 30
         if (optimumCameraConfig == null) {
            for (item in cameraConfig) {
               if (item.fps == 30) {
                  if (item.width > (optimumCameraConfig?.width ?: 0)) {
                     optimumCameraConfig = item
                  }
               }
            }
         }
         optimumCameraConfig?.let { cameraConfig ->
            arView?.setCameraConfiguration(cameraConfig)
         }
      }
   }

   fun setExperienceView(view: View) {
      experienceview = view
      experienceLayer?.let {
         experienceLayer?.addView(view)
         experienceLayer?.bringToFront()
      }
   }

   inner class ARSceneListener(activity: Activity) : ARScene.Listener {
      private val activity: WeakReference<Activity> = WeakReference(activity)
      private var mInitialized: Boolean = false
      var trackingState : ARScene.TrackingState? = null

      override fun onTrackingInitialized() {

      }

      override fun onTrackingUpdated(
         trackingState: ARScene.TrackingState?, trackingStateReason: ARScene.TrackingStateReason?
      ) {
         if (!mInitialized && trackingState == ARScene.TrackingState.NORMAL) {
            val activity = activity.get() ?: return
            mInitialized = true
         }
         this.trackingState = trackingState
         sportsExperienceController?.updateTrackingState()
      }

      override fun onAmbientLightUpdate(p0: Float, p1: Vector?) {

      }

      override fun onAnchorFound(p0: ARAnchor?, p1: ARNode?) {

      }

      override fun onAnchorUpdated(p0: ARAnchor?, p1: ARNode?) {

      }

      override fun onAnchorRemoved(p0: ARAnchor?, p1: ARNode?) {

      }

   }

   private fun createSportExperienceController(
      sports: SPORT, experience: EXPERIENCE, context: AppCompatActivity
   ) {
      when {
         sports == SPORT.BASKETBALL && experience == EXPERIENCE.VENUE -> {
            sportsExperienceController = basketballVenue(this, context)
         }
      }
   }

   override fun onStart() {
      super.onStart()
      arView?.onActivityStarted(activity)
   }

   override fun onResume() {
      super.onResume()
      arView?.onActivityResumed(activity)
   }

   override fun onPause() {
      arView?.onActivityPaused(activity)
      super.onPause()
   }

   override fun onStop() {
      arView?.onActivityStopped(activity)
      super.onStop()
   }

   override fun onDestroy() {
      arView?.onActivityDestroyed(activity)
      super.onDestroy()
   }
   fun enableRegistration(enabled: Boolean) {
      tracker?.enableRegistration(enabled)
   }
}