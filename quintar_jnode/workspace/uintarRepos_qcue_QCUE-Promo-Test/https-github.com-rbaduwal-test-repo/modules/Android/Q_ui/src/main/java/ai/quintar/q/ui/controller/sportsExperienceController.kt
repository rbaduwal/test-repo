package ai.quintar.q.ui.controller

import ai.quintar.q.ui.arUiViewController
import androidx.appcompat.app.AppCompatActivity

@Suppress("ClassName") interface sportsExperienceController {
   var arViewController: arUiViewController
   fun initialize(context: AppCompatActivity)
   fun enableTestMode(enabled: Boolean)
   fun showOutline(enabled: Boolean)
   fun updateTrackingState()
   fun storeUUID(uuid: String)
}
