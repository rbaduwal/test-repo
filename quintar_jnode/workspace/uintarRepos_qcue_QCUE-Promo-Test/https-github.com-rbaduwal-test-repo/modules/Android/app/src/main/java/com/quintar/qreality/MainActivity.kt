package com.quintar.qreality

import ai.quintar.q.utility.bundleDownloader
import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import com.viro.core.ARScene
import com.viro.core.ViroViewARCore


class MainActivity : AppCompatActivity() {
    private var mViroView: ViroViewARCore? = null
    private var mScene: ARScene? = null
    @SuppressLint("WrongThread")
    override fun onCreate(savedInstanceState: Bundle?) {
        this.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val bundle= bundleDownloader(this)
        bundle.getImageAsync("testimage.jpeg"){

        }
//        val v: View // Creating an instance for View Object
//        val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
//        v = inflater.inflate(R.layout.overlay_sample, null)
//        val fragmentManager = supportFragmentManager
//        val transaction = fragmentManager.beginTransaction()
//        transaction.replace(R.id.host, arUiViewController())
//        transaction.addToBackStack(null)
//        transaction.commit()
        getDeviceStatus(
            onSuccess = { w ->
                Log.d("respo",w.toString())
            }
        ) { e ->
            Log.d("respo",e.toString())
        }
    }

    private fun getDeviceStatus(onSuccess: (Any) -> Unit, onFailure: (Any) -> Unit) {
        onSuccess("success")
        onFailure("Failure")
    }
}