package ai.quintar.q.ui

import ai.quintar.q.connect.sceneIntrinsic
import ai.quintar.q.ui.controller.sportsExperienceController
import ai.quintar.q.ui.internal.sensorManager
import ai.quintar.q.utility.ERROR
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.viro.core.Matrix
import com.viro.core.Node
import com.viro.core.Vector
import java.io.ByteArrayOutputStream
import java.lang.ref.WeakReference
import java.util.*
import kotlin.concurrent.timer

@Suppress("ClassName")
open class venue(override var arViewController: arUiViewController) : sportsExperienceController {
   companion object {
      var Q_NOTIFICATION_ON_TRACKING_UPDATED = "Q_NOTIFICATION_ON_TRACKING_UPDATED"
      var Q_NOTIFICATION_ON_READY_FOR_TRACKING =  "Q_NOTIFICATION_ON_READY_FOR_TRACKING"
   }

   private var gson = Gson()
   protected var worldRootEntity: Node? = null
   private var outlineRootEntity: Node? = null
   private var testSceneIntrinsic: sceneIntrinsic? = null
   private var sceneIntrinsic: sceneIntrinsic? = null
   private var context: WeakReference<AppCompatActivity>? = null
   private var testModeEnabled: Boolean = true
   private var showOutline: Boolean = true
   private var sensorManager: sensorManager? = null
   public var isReadyForTracking : Boolean = false
   private var trackingSmoothMoveAnimationFrame = 0f
   private var trackingSmoothMoveAnimationMaxFrame = 30f
   private var newCorrection: ArrayList<Double>? = arrayListOf()
   private var oldCorrection: List<Double> = arrayListOf(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    )
   private var uuid: String? = null

   override fun initialize(context: AppCompatActivity) {
      this.context = WeakReference(context)
      worldRootEntity = Node()
      outlineRootEntity = Node()
      addSportsRootEntity()
      readRegistrationTestData()
      sensorManager = sensorManager(context,this)
   }

   override fun enableTestMode(enabled: Boolean) {
      this.testModeEnabled = enabled
   }

   override fun showOutline(enabled: Boolean) {
      this.showOutline = enabled
      this.outlineRootEntity?.isVisible = enabled
   }

   override fun updateTrackingState() {
      isReadyForTracking = sensorManager?.isReadyForTracking == true
      arViewController?.tracker?.isReadyForTracking(isReadyForTracking)
      val intent = Intent(Q_NOTIFICATION_ON_READY_FOR_TRACKING)
      intent.putExtra("isReadyForTracking", isReadyForTracking)
      context?.get()?.sendBroadcast(intent)
   }
   
   override fun storeUUID(uuid: String) {
      this.uuid = uuid
   }

   private fun addSportsRootEntity() {
      worldRootEntity?.isVisible = false
      this.arViewController.mScene?.rootNode?.addChildNode(worldRootEntity)
   }

   private fun getLocationID(): String {
      return "observatory_arena_court0"
   }

   private fun createOutline() {
      this.worldRootEntity?.addChildNode(this.outlineRootEntity)
      this.arViewController.arUiConfig.downloader?.let { downloader ->
         this.arViewController.arUiConfig.arConfig?.test?.fops?.get(0)?.outlines?.let { outlines ->
            for (outline in outlines) {
               try {
                  // Will throw exception in case of error
                  val outlineValue = downloader.getJson(outline.outlineUrl.toString())
                  val outlineData = gson.fromJson(
                     outlineValue.result.toString(), outlineModel::class.java
                  )
                  outlineData?.segments?.let { segments ->
                     for (segmentIndex in 0 until segments.size) {
                        val points = ArrayList<Vector>()
                        val segment = segments[segmentIndex]
                        for (index in 0 until segment.size) {
                           val point = segment[index]
                           points.add(Vector(point.X, point.Y, point.Z))
                        }
                        this.outlineRootEntity?.addChildNode(outlineSceneGraphNode(points, outline))
                     }
                  }
               } catch (e: Exception) {
                  Log.d("Error", "Failed to parse data")
               }
            }
         }
      }
   }

   private fun setTrackingMatrix(transform: List<Double>) {
      val correctionMatrix = Matrix(transform.toDoubleArray().map { it.toFloat() }.toFloatArray())
      constants.correctionMatrix = correctionMatrix
      val scale = correctionMatrix.extractScale()
      this.worldRootEntity?.setScale(scale)
      this.worldRootEntity?.setRotation(correctionMatrix.extractRotation(scale))
      this.worldRootEntity?.setPosition(correctionMatrix.extractTranslation())
      this.worldRootEntity?.isVisible = true
      this.oldCorrection = transform
   }

   fun isDeviceReadyForTracking(context: Context): Boolean? {
      var isDeviceReady: Boolean = false
      if (sensorManager?.deviceInPocket == false) {
         isDeviceReady = false
      }
      return isDeviceReady
   }

   private fun readRegistrationTestData() {
      this.arViewController.arUiConfig.downloader?.let { downloader ->
         this.arViewController.arUiConfig.arConfig?.test?.fops?.get(0)?.testJsonUrl?.let {
               testJsonUrl ->
            downloader.getJsonAsync(testJsonUrl) {
               try {
                  this.getTestImage()?.let { testImage ->
                     val stream = ByteArrayOutputStream()
                     testImage.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                     val testImageByteData = stream.toByteArray()

                     val testJson = gson.fromJson(
                        it.result.toString(),
                        testJsonModel::class.java
                     )
                     //get camera transform
                     val cameraTransform = gson.fromJson(
                        testJson.camXform.toString(),
                        DoubleArray::class.java
                     )
                     val cameraIntrinsics = gson.fromJson(
                        testJson.camIntrinsics.toString(),
                        DoubleArray::class.java
                     )
                     val gravity = gson.fromJson(
                        testJson.gravity.toString(),
                        DoubleArray::class.java
                     )
                     val compass = gson.fromJson(
                        testJson.compass.toString(),
                        DoubleArray::class.java
                     )

                     this.testSceneIntrinsic = uuid?.let { uuid ->
                        Log.e("test","uuid ${uuid}")
                        sceneIntrinsic(
                           cameraTransform,
                           cameraIntrinsics,
                           testJson.lat,
                           testJson.lon,
                           testJson.altitude,
                           testJson.latlonAccuracy,
                           testJson.altitudeAccuracy,
                           compass,
                           gravity,
                           testImageByteData,
                           testImage.width,
                           testImage.height,
                           testJson.epochSecs,
                           testJson.misc,
                           getLocationID(),
                           getDeviceName().toString(),
                           constants.deviceType,
                           testJson.headingAccuracy,
                           0F,
                           true,
                           uuid
                        )
                     }
                  }
               } catch (exception: Exception) {
                  exception.printStackTrace()
                  this.testSceneIntrinsic = null
               }
            }
         }
      }
   }

   private fun createRegistrationData() {
      try {
         arViewController.arView?.getARFrameImage()
         {
            it?.let { arObject ->
               arObject.buffer?.let { bufferValue ->
                  //getting real image data
                  val bitmap = Bitmap.createBitmap(
                     arObject.width,
                     arObject.height,
                     Bitmap.Config.ARGB_8888
                  )
                  bitmap.copyPixelsFromBuffer(bufferValue.position(0))
                  val stream = ByteArrayOutputStream()
                  bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                  val imageByteData = stream.toByteArray()
                  val principalPoint = arObject.principalPoint
                  val focalLength = arObject.focalLength

                  //creating cameraIntrisic values from focal length and principal point
                  val cameraIntrinsics = doubleArrayOf(
                     focalLength[0].toDouble(),
                     0.0,
                     0.0,
                     0.0,
                     focalLength[1].toDouble(),
                     0.0,
                     principalPoint[0].toDouble(),
                     principalPoint[1].toDouble(),
                     1.0
                  )

                  //get camera transformation data
                  val cameraTransformData = arObject.translation_applied_rotation_array
                  val cameraTransform = DoubleArray(cameraTransformData.size)
                  for (index in cameraTransformData.indices) {
                     cameraTransform[index] = cameraTransformData[index].toDouble()
                  }
                  val compassValues = sensorManager?.compassValues
                  val gravityValues = sensorManager?.gravityValues
                  compassValues?.let { compassValues ->
                     gravityValues?.let { gravityValues ->
                        this.sceneIntrinsic = uuid?.let { uuid ->
                           sceneIntrinsic(
                              cameraTransform,
                              cameraIntrinsics,
                              0.0,
                              0.0,
                              0.0,
                              0.0,
                              0.0,
                              compassValues,
                              gravityValues,
                              imageByteData,
                              arObject.width,
                              arObject.height,
                              System.currentTimeMillis(),
                              constants.liveMisc,
                              getLocationID(),
                              getDeviceName().toString(),
                              constants.deviceType,
                              constants.headingAccuracy,
                              0F,
                              true,uuid
                           )
                        }
                     }
                  }
               }
            }
         }
      } catch (exception: Exception) {
         exception.printStackTrace()
         this.sceneIntrinsic = null
      }
   }

   private fun getTestImage(): Bitmap? {
        var bitmap: Bitmap? = null
        val downloader = this.arViewController.arUiConfig.downloader
        val testJson = this.arViewController.arUiConfig.arConfig?.test?.fops?.get(0)?.testImageUrl
        if (testJson != null) {
            downloader?.getImageAsync(testJson) {
                bitmap = it.result
            }
        }
        return bitmap
    }

   fun getDeviceName(): String? {
        val manufacturer = Build.MANUFACTURER
        val model = Build.MODEL
        return if (model.startsWith(manufacturer)) {
            capitalize(model)
        } else capitalize(manufacturer) + " " + model
    }

   private fun capitalize(str: String): String {
        if (TextUtils.isEmpty(str)) {
            return str
        }
        val arr = str.toCharArray()
        var capitalizeNext = true
        var phrase = ""
        for (c in arr) {
            if (capitalizeNext && Character.isLetter(c)) {
                phrase += Character.toUpperCase(c)
                capitalizeNext = false
                continue
            } else if (Character.isWhitespace(c)) {
                capitalizeNext = true
            }
            phrase += c
        }
        return phrase
    }

   fun startTracking() {
        var animationTimer: Timer? = null
        arViewController.tracker?.startTracking(
            {
                getTestSceneIntrinsic()
            },
            { trackingUpdate ->
                val intent = Intent(Q_NOTIFICATION_ON_TRACKING_UPDATED)
                if (trackingUpdate.error == ERROR.NONE) {
                    intent.putExtra("result", trackingUpdate)
                    trackingUpdate.transform?.let { transform ->
                        this.newCorrection?.clear()
                        this.newCorrection?.addAll(transform)
                        //this.setTrackingMatrix(transform)
                    }
                    if (this.outlineRootEntity?.parentNode == null) {
                        this.createOutline()
                    }
                    val timeInterval =
                        (arViewController?.arUiConfig?.arConfig?.outlineAnimationDelay?.div(
                            trackingSmoothMoveAnimationMaxFrame
                        )?.toLong() ?: 100L
                                )

                    animationTimer =
                        timer("OutlineInterpolation", false, timeInterval, timeInterval) {
                            Handler(Looper.getMainLooper()).post {
                                if (trackingSmoothMoveAnimationFrame >= trackingSmoothMoveAnimationMaxFrame) {
                                    animationTimer?.cancel()
                                    trackingSmoothMoveAnimationFrame = 0f
                                } else {
                                    outlineRootEntity?.isVisible = true
                                    onTrackingSmoothMoveTick()
                                }
                            }
                        }
                } else {
                    intent.putExtra("result", trackingUpdate)
                }
                context?.get()?.sendBroadcast(intent)
            }
        )
    }

   private fun onTrackingSmoothMoveTick() {
        trackingSmoothMoveAnimationFrame += 1f
        val timeOfFrame = (trackingSmoothMoveAnimationFrame / trackingSmoothMoveAnimationMaxFrame)
        val smoothMoveFromTransform = get2DMatrixFromList(this.oldCorrection, 4)
        val smoothMoveToTransform = this.newCorrection?.let { get2DMatrixFromList(it, 4) }
        val multipliedFrom = scalarProductMat(smoothMoveFromTransform, (1 - timeOfFrame))
        val multipliedTo = smoothMoveToTransform?.let { scalarProductMat(it, timeOfFrame) }
        val addTransform = multipliedTo?.let { addMatrix(multipliedFrom, it) }
        val frameTransform: MutableList<Double> = mutableListOf()

        if (addTransform != null) {
            for (row in addTransform) {
                for (column in row) {
                    frameTransform.add(column)
                }
            }
        }
        this.setTrackingMatrix(frameTransform)
    }

   @JvmName("getTestSceneIntrinsic1")
   private fun getTestSceneIntrinsic(): sceneIntrinsic? {
        return if (this.testModeEnabled) {
            this.testSceneIntrinsic
        } else {
            createRegistrationData()
            this.sceneIntrinsic
        }
    }

   open fun scalarProductMat(transform: Array<DoubleArray>, k: Float): Array<DoubleArray> {
        val someArray = Array(4)
        {
            DoubleArray(4)
        }
        for (i in 0 until 4) {
            for (j in 0 until 4) {
                someArray[i][j] = (transform[i][j]).toDouble() * k.toDouble()
            }
        }
        return someArray
    }

   private fun get2DMatrixFromList(list: List<Double>, n: Int): Array<DoubleArray> {
        val outerArray = Array(4) {
            DoubleArray(4)
        }
        var outerCounter = 0
        var innerCounter = 0

        for (value in 0 until 16) {
            outerArray[outerCounter][innerCounter] = list[value].toDouble()
            innerCounter++
            if (innerCounter % n == 0) {
                innerCounter = 0
                outerCounter++
            }
        }
        return outerArray
    }

   private fun addMatrix(m1: Array<DoubleArray>, m2: Array<DoubleArray>): Array<DoubleArray> {
        val sum = Array(4)
        {
            DoubleArray(4)
        }
        for (i in 0 until 4) {
            for (j in 0 until 4) {
                sum[i][j] = m1[i][j] + m2[i][j]
            }
        }
        return sum
   }

   data class outlineModel(
        @SerializedName("Radius") var radius: Int? = null,
        @SerializedName("Segments") var segments: ArrayList<ArrayList<segments>> = arrayListOf()
    )

   data class segments(
        @SerializedName("X") var X: Double = 0.0,
        @SerializedName("Y") var Y: Double = 0.0,
        @SerializedName("Z") var Z: Double = 0.0
    )

   data class testJsonModel(
        @SerializedName("altitude") var altitude: Double = 0.0,
        @SerializedName("epochSecs") var epochSecs: Long = 0,
        @SerializedName("exposure") var exposure: Int = 0,
        @SerializedName("lon") var lon: Double = 0.0,
        @SerializedName("camIntrinsics") var camIntrinsics: ArrayList<Double> = arrayListOf(),
        @SerializedName("compass") var compass: ArrayList<Double> = arrayListOf(),
        @SerializedName("camXform") var camXform: ArrayList<Double> = arrayListOf(),
        @SerializedName("misc") var misc: String = "",
        @SerializedName("latlonAccuracy") var latlonAccuracy: Double = 0.0,
        @SerializedName("lat") var lat: Double = 0.0,
        @SerializedName("altitudeAccuracy") var altitudeAccuracy: Double = 0.0,
        @SerializedName("imgWidth") var imgWidth: Int = 0,
        @SerializedName("frameNumber") var frameNumber: Int? = null,
        @SerializedName("gravity") var gravity: ArrayList<Double> = arrayListOf(),
        @SerializedName("imgHeight") var imgHeight: Int = 0,
        @SerializedName("headingAccuracy") var headingAccuracy: Double = 0.0
    )
}