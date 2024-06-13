package ai.quintar.sandbox

import ai.quintar.q.ui.config.arUIViewConfig
import ai.quintar.q.ui.controller.arUiViewController
import ai.quintar.q.ui.controller.basketballVenueController
import ai.quintar.q.utility.httpDownloader
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.widget.Switch
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout

class MainActivity : AppCompatActivity() {
    private var httpDownloader: httpDownloader? = null
    private lateinit var baselayout: ConstraintLayout
    private lateinit var splashlayout: ConstraintLayout
    private lateinit var syncingtext: TextView
    private lateinit var testModeSwitch: Switch
    private var arUIViewConfig: arUIViewConfig? = null
    private var arUiViewController: arUiViewController? = null
    private var basketballVenueController: basketballVenueController? = null
    private var experienceLayer: experienceLayer? = null
    private var preferences: preferences? = null
    val url = "https://nbadatalakedev.blob.core.windows.net/nba/nba_sdk/arUiView.json"

    override fun onCreate(savedInstanceState: Bundle?) {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        preferences = preferences(this)
        baselayout = findViewById(R.id.host)
        splashlayout = findViewById(R.id.splashlayout)
        syncingtext = findViewById(R.id.syncingtext)
        testModeSwitch = findViewById(R.id.testmodeenable)
        httpDownloader = httpDownloader()
        httpDownloader?.let {
            arUIViewConfig = arUIViewConfig(url, it) {
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
                runOnUiThread {
                    syncingtext.text = getString(R.string.orientationLandscapeChange)
                    testModeSwitch.isEnabled = true
                    setARView()
                    setExperienceView()
                    settingUIBasedOnConfiguration()
                }
            }
        }
    }

    private fun settingUIBasedOnConfiguration() {
        //ckecks current orientation of screen and handle layout visibility
        val orientation = resources.configuration.orientation
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            baselayout.visibility = View.VISIBLE
            splashlayout.visibility = View.GONE
        } else {
            baselayout.visibility = View.GONE
            splashlayout.visibility = View.VISIBLE
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Checks the orientation of the screen
        if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            baselayout.visibility = View.VISIBLE
            splashlayout.visibility = View.GONE
        } else if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT) {
            baselayout.visibility = View.GONE
            splashlayout.visibility = View.VISIBLE
        }
    }

    private fun setARView() {
        arUIViewConfig?.let {
            if (arUiViewController == null) {
                arUiViewController = arUiViewController(it, this)
                setTestModeEnableSwitchListener()
                loadTestModeEnablePreviousState()
            }
            arUiViewController?.let { arUiViewController ->
                basketballVenueController =
                    (arUiViewController.sportsExperienceController as? basketballVenueController)
                val fragmentManager = supportFragmentManager
                val transaction = fragmentManager.beginTransaction()
                transaction.replace(R.id.host, arUiViewController)
                transaction.addToBackStack(null)
                transaction.commitAllowingStateLoss()
            }
        }
    }

    private fun loadTestModeEnablePreviousState() {
        val previousTestModeEnableValue = preferences?.getTestmodeEnable()
        previousTestModeEnableValue?.let {
            arUiViewController?.enableTestMode(it)
            testModeSwitch.isChecked = it
        }
    }

    private fun setTestModeEnableSwitchListener() {
        testModeSwitch.setOnCheckedChangeListener { buttonView, isChecked ->
            arUiViewController?.enableTestMode(isChecked)
            preferences?.setTestmodeEnable(isChecked)
        }
    }

    private fun setExperienceView() {
        basketballVenueController?.let {
            experienceLayer = experienceLayer(this, it)
            experienceLayer?.let { layer ->
                arUiViewController?.setExperienceView(layer.experienceView)
            }
        }
    }
}
