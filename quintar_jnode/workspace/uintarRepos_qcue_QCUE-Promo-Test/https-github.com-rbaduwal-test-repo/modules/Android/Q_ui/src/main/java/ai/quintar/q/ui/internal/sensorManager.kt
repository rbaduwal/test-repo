package ai.quintar.q.ui.internal

import ai.quintar.q.ui.venue
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.appcompat.app.AppCompatActivity
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.atan2
import kotlin.math.roundToInt
import kotlin.math.sqrt

class sensorManager(context: AppCompatActivity, var venueController : venue) : SensorEventListener {
   private var mSensorManager: SensorManager? = null
   private var compassValue = DoubleArray(3)
   private var gravityValue = DoubleArray(3)
   private var mProximity = -1f
   private var mLight = -1f
   private var mAccelerometer = floatArrayOf(0f, 0f, 0f)
   private var inclination = -1
   private var isDeviceInPocket = false
   private var mAngle = 90
   private var readyForTracking = false

   init {
      mSensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
      mSensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)?.also { magneticField ->
         mSensorManager?.registerListener(
            this, magneticField, SensorManager.SENSOR_DELAY_NORMAL, SensorManager.SENSOR_DELAY_UI
         )
      }
      mSensorManager?.getDefaultSensor(Sensor.TYPE_GRAVITY)?.also { gravity ->
         mSensorManager?.registerListener(
            this, gravity, SensorManager.SENSOR_DELAY_NORMAL, SensorManager.SENSOR_DELAY_UI
         )
      }
      mSensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.also { accelerometer ->
         mSensorManager?.registerListener(
            this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL, SensorManager.SENSOR_DELAY_UI
         )
      }
      mSensorManager?.getDefaultSensor(Sensor.TYPE_PROXIMITY)?.also { proximity ->
         mSensorManager?.registerListener(
            this, proximity, SensorManager.SENSOR_DELAY_NORMAL, SensorManager.SENSOR_DELAY_UI
         )
      }
      mSensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)?.also { light ->
         mSensorManager?.registerListener(this, light, SensorManager.SENSOR_DELAY_NORMAL,SensorManager.SENSOR_DELAY_UI)
      }

   }

   val gravityValues: DoubleArray
      get() {
         return gravityValue
      }
   val compassValues: DoubleArray
      get() {
         return compassValue
      }
   val deviceInPocket: Boolean
      get() {
         return isDeviceInPocket
      }
   val deviceAngle: Int
      get() {
         return mAngle
      }
   val lightIntensity: Float
      get() {
         return mLight
      }
   val isReadyForTracking: Boolean
      get() {
         return readyForTracking
      }

   override fun onSensorChanged(event: SensorEvent?) {
      val sensor = event?.sensor
      if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) {
         compassValue = DoubleArray(event.values.size)
         for (index in event.values.indices) {
            compassValue[index] = event.values[index].toDouble()
         }
      } else if (sensor?.type == Sensor.TYPE_GRAVITY) {
         gravityValue = DoubleArray(event.values.size)
         for (index in event.values.indices) {
            gravityValue[index] = event.values[index].toDouble()
         }
      }
      if (sensor?.type == Sensor.TYPE_ACCELEROMETER) {
         mAccelerometer = FloatArray(3)
         mAccelerometer = event.values.clone()
         val normalizationFactor =
            sqrt((mAccelerometer[0] * mAccelerometer[0] + mAccelerometer[1] * mAccelerometer[1] +
               mAccelerometer[2] * mAccelerometer[2]))
         mAccelerometer[0] = (mAccelerometer[0] / normalizationFactor)
         mAccelerometer[1] = (mAccelerometer[1] / normalizationFactor)
         mAccelerometer[2] = (mAccelerometer[2] / normalizationFactor)
         inclination = Math.toDegrees(acos(mAccelerometer[2]).toDouble()).roundToInt()
         mAngle = (atan2(
            mAccelerometer[0].toDouble(), mAccelerometer[1].toDouble()
         ) / (Math.PI / 180)).roundToInt()
      }
      if (sensor?.type == Sensor.TYPE_PROXIMITY) {
         mProximity = event.values[0]
      }
      if (sensor?.type == Sensor.TYPE_LIGHT) {
         mLight = event.values[0]
      }
      //The main signs that the phone is in a pocket are: little light,
      // vertical upside-down position and lack of space. These parameters can
      // be obtained by the Light sensor, Accelerometer and Proximity sensor.
      if (mProximity != -1f && mLight != -1f && inclination != -1) {
         detect(mProximity, mLight, mAccelerometer, inclination)
      }
      isReadyForTracking(mAngle,mLight,gravityValue)
   }

   private fun detect(
      mProximity: Float, mLight: Float, mAccelerometer: FloatArray, inclination: Int
   ) {
      if ((mProximity < 1) && (mLight < 2) && (mAccelerometer[1] < -0.6) && ((inclination > 75)
            || (inclination < 100))) {
         isDeviceInPocket = true
      }
      if ((mProximity >= 1) && (mLight >= 2) && (mAccelerometer[1] >= -0.7)) {
         isDeviceInPocket = false
      }
   }

   private  fun isReadyForTracking(angle : Int,lightIntensity : Float,gravityValues : DoubleArray)
   {
     readyForTracking = (angle > 45 && angle < 135) &&
        (lightIntensity >= 100 &&
      !((abs(gravityValues?.get(0)) <  Math.abs(gravityValues?.get(1))) ||
         (abs(gravityValues?.get(0)) < Math.abs(gravityValues?.get(2)))))
      venueController?.updateTrackingState()
   }

   override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
   }
}