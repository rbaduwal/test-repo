package ai.quintar.basketball

import ai.quintar.basketball.ExperienceWrapper.basketballVenueExperience
import ai.quintar.q.utility.ERROR
import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {
   private var basketballVenueExperience: basketballVenueExperience? = null

   @SuppressLint("SetTextI18n")
   override fun onCreate(savedInstanceState: Bundle?) {
      requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
      window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
      super.onCreate(savedInstanceState)
      setContentView(R.layout.activity_main)
      version.text = "V " + BuildConfig.VERSION_CODE.toString() + "." + BuildConfig.VERSION_NAME

      //initializing basketballVenueExperience
      basketballVenueExperience =
         basketballVenueExperience(getString(R.string.ar_ui_config_url), this) { arUIViewUpdate ->
            when(arUIViewUpdate.statusCode){
               ERROR.NONE->{
                  runOnUiThread {
                     basketballVenueExperience?.enterAR()
                     settingUIBasedOnConfiguration()
                     syncingtext.text = getString(R.string.orientationLandscapeChange)
                     requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
                  }
               }
               else->{
                  Log.d("error","config data not available")
               }
            }
         }
   }

   //ckecks current orientation of screen and handle layout visibility
   private fun settingUIBasedOnConfiguration() {
      val orientation = resources.configuration.orientation
      if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
         enterAr()
      } else {
         leaveAR()
      }
   }

   //enable portrait screen and disable AR screen
   private fun leaveAR() {
      host.visibility = View.INVISIBLE
      splashlayout.visibility = View.VISIBLE
   }

   //enable AR screen and disable portrait screen
   private fun enterAr() {
      host.visibility = View.VISIBLE
      splashlayout.visibility = View.INVISIBLE
   }

   // Checks the orientation of the screen
   override fun onConfigurationChanged(newConfig: Configuration) {
      super.onConfigurationChanged(newConfig)
      if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
         enterAr()
      } else if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT) {
         leaveAR()
      }
   }
}
