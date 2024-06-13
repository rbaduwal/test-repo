@file:Suppress("ClassName")

package ai.quintar.sandbox

import ai.quintar.q.ui.controller.basketballVenueController
import ai.quintar.q.utility.ERROR
import ai.quintar.q.utility.trackingUpdate
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.view.LayoutInflater
import android.view.View
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity

class experienceLayer(private var context: Context, venueController: basketballVenueController) {
    var experienceView: View
        private set
    private var isTrackingStarted = false
    private var registration: ImageView
    private var connectingAnimation: Animation? = null

    private val mMessageReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent) {
            val result = intent.getSerializableExtra("result") as trackingUpdate
            stopRegistrationAnimation(result)
        }
    }

    init {
        context.registerReceiver(
            mMessageReceiver,
            IntentFilter(basketballVenueController.Q_NOTIFICATION_ON_TRACKING_UPDATED)
        )

        val inflater =
            context.getSystemService(AppCompatActivity.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        experienceView = inflater.inflate(R.layout.experience_layer_layout, null)
        registration = experienceView.findViewById(R.id.register)
        registration.setOnClickListener {
            if (!isTrackingStarted) {
                isTrackingStarted = true
                venueController.startTracking()

                startRegistrationAnimation()
            }
        }
    }

    private fun startRegistrationAnimation() {
        registration.setImageResource(R.drawable.basketballorange)
        connectingAnimation = AnimationUtils.loadAnimation(this.context, R.anim.alpha_animation)
        connectingAnimation?.let {
            registration.startAnimation(it)
        }
    }

    fun stopRegistrationAnimation(trackingUpdate: trackingUpdate) {
        registration.clearAnimation()
        connectingAnimation?.cancel()
        connectingAnimation?.reset()
        if (trackingUpdate.status == ERROR.NONE) {
            registration.setImageResource(R.drawable.basketballorange)
        } else {
            registration.setImageResource(R.drawable.basketballwhite)
        }
    }
}