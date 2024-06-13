package ai.quintar.q.ui

import android.content.Context
import android.util.DisplayMetrics
import com.viro.core.Matrix

object constants {
   var correctionMatrix: Matrix = Matrix()
   fun convertDpToPixel(dp: Int, context: Context): Int {
      return dp * (context.resources.displayMetrics.densityDpi / DisplayMetrics.DENSITY_DEFAULT)
   }

   var deviceType = "Android"
   var headingAccuracy = -1.0
   var liveMisc = "From Android App"
   var teamLeaderBoardScale = 40f
   var teamLeaderBoardSize = 5f
   var playerCardBoardSize = 10f
   var playerCardScale = 40f
   var courtsideBoardAnimationSpeed = 500
   var courtsideBoardDistanceFromCamera = 0f
   var courtHalfWidth = 25
   var courtHalfLength = 47
   var courtsideBoardDistanceFromFloor = 30f
   var boardExtraWidth = 1000
   var fixedBoardHeight = 0.6f
   //constants for out of the arena
   var insufficientFeatureMatches = "insufficientFeatureMatches"
   var outOfTheArena = "Out of arena"
   //constants for handling pocket registration
   var phoneInPocket = "Phone in pocket"
   var NO_NETWORK_TITLE = ""
   var NO_NETWORK_DESCRIPTION = ""
}