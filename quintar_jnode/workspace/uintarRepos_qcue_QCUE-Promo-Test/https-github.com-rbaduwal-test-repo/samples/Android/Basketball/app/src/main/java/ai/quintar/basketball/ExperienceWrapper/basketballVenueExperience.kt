package ai.quintar.basketball.ExperienceWrapper

import ai.quintar.basketball.R
import ai.quintar.q.ui.arUiViewConfig
import ai.quintar.q.ui.arUiViewUpdate
import ai.quintar.q.ui.arUiViewController
import ai.quintar.q.ui.basketball.basketballVenue
import ai.quintar.q.utility.ERROR
import androidx.appcompat.app.AppCompatActivity

class basketballVenueExperience {
   private var arUiViewController: arUiViewController? = null
   private var sdkConfig: arUiViewConfig? = null
   var basketballVenue: basketballVenue? = null
   private var context: AppCompatActivity

   constructor(
      url: String,
      context: AppCompatActivity,
      callbackWhenDone: (d: arUiViewUpdate) -> Unit
   ) {
      this.context = context

      //getting arUIView config from online/offline
      sdkConfig = arUiViewConfig(url) {
         when (it.error) {
            ERROR.NONE -> {

               //initializing arUIView controller which is a view includes both
               //AR view and experience view
               if (arUiViewController == null) {
                  arUiViewController = arUiViewController(it.config as arUiViewConfig, context)
               }
               arUiViewController?.let { arUiViewController ->
                  val fragmentManager = context.supportFragmentManager
                  val transaction = fragmentManager.beginTransaction()
                  transaction.replace(R.id.host, arUiViewController)
                  transaction.addToBackStack(null)
                  transaction.commitAllowingStateLoss()
                  basketballVenue =
                     (arUiViewController.sportsExperienceController as? basketballVenue)
               }
               val success = arUiViewUpdate(ERROR.NONE, "", it.config as arUiViewConfig)
               callbackWhenDone(success)
            }
            else -> {
               val failure = arUiViewUpdate(ERROR.INIT, "", it.config as arUiViewConfig)
               callbackWhenDone(failure)
            }
         }
      }
   }

   //adding experience view in arUIViewController
   fun enterAR() {
      basketballVenue?.let { basketballVenue ->
         val experienceLayer = experienceView(context, basketballVenue)
         experienceLayer.let { layer ->
            arUiViewController?.setExperienceView(layer.experienceView)
            experienceLayer.setBottomBar()
         }
      }
   }
}