@file:Suppress("ClassName")

package ai.quintar.basketball.ExperienceWrapper

import ai.quintar.basketball.ExperienceWrapper.CarouselView.bottomView
import ai.quintar.basketball.R
import ai.quintar.q.connect.trackingUpdate
import ai.quintar.q.ui.basketball.basketballVenue
import ai.quintar.q.utility.ERROR
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.view.LayoutInflater
import android.view.View
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import androidx.appcompat.app.AppCompatActivity
import kotlinx.android.synthetic.main.experience_layer_layout.view.*


class experienceView(
   private var context: Context, private var venueController: basketballVenue
) {
   var experienceView: View
      private set
   private var activityContext: Activity? = null
   private var isTrackingStarted = false
   private var connectingAnimation: Animation? = null
   private var bottomView: bottomView? = null

   private val mMessageReceiver: BroadcastReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context?, intent: Intent) {
         val result = intent.getSerializableExtra("result") as trackingUpdate
         stopRegistrationAnimation(result)
      }
   }

   init {
      this.activityContext = context as Activity
      context.registerReceiver(
         mMessageReceiver, IntentFilter(basketballVenue.Q_NOTIFICATION_ON_TRACKING_UPDATED)
      )
      val inflater =
         context.getSystemService(AppCompatActivity.LAYOUT_INFLATER_SERVICE) as LayoutInflater
      experienceView = inflater.inflate(R.layout.experience_layer_layout, null)
      experienceView.taptobeginlayout.setOnClickListener {
         if (!isTrackingStarted) {
            experienceView.taptobeginlayout.visibility = View.GONE
            isTrackingStarted = true
            venueController.startTracking()
            startRegistrationAnimation()
         }
      }
      experienceView.register.setOnClickListener {
         if (!isTrackingStarted) {
            experienceView.taptobeginlayout.visibility = View.GONE
            isTrackingStarted = true
            venueController.startTracking()
            startRegistrationAnimation()
         }
      }
   }

   //starting registration
   private fun startRegistrationAnimation() {
      experienceView.register.setImageResource(R.drawable.basketballorange)
      connectingAnimation = AnimationUtils.loadAnimation(this.context, R.anim.alpha_animation)
      connectingAnimation?.let {
         experienceView.register.startAnimation(it)
      }
   }

   //stopping registration
   fun stopRegistrationAnimation(trackingUpdate: trackingUpdate) {
      experienceView.register.clearAnimation()
      connectingAnimation?.cancel()
      connectingAnimation?.reset()
      if (trackingUpdate.error == ERROR.NONE) {
         experienceView.register.setImageResource(R.drawable.basketballorange)
         experienceView.taptobeginlayout.visibility = View.GONE
      } else {
         experienceView.register.setImageResource(R.drawable.basketballwhite)
         experienceView.taptobeginlayout.visibility = View.VISIBLE
      }
   }

   //setting bottombar actions
   fun setBottomBar() {
      bottomView = bottomView(
         context as AppCompatActivity, experienceView
      )
      bottomView?.initializeBottomBar()
   }
}