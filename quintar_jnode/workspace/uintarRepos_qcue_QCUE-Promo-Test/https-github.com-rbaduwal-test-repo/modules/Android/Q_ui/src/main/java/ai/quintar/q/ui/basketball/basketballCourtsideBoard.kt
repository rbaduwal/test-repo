package ai.quintar.q.ui.basketball

import ai.quintar.q.ui.constants
import com.viro.core.Node
import com.viro.core.Quaternion
import com.viro.core.Vector
import java.util.*
import kotlin.concurrent.timer
import kotlin.math.atan2

open class basketballCourtsideBoard : Node() {
   enum class LOCATION {
      COURTSIDE, USER, UNKNOWN
   }

   var location: LOCATION = LOCATION.UNKNOWN
      private set
   var distanceFromFloor: Float = constants.courtsideBoardDistanceFromFloor
   var distanceFromCamera: Float = constants.courtsideBoardDistanceFromCamera
   var cardAnimationDelay: Float = constants.courtsideBoardAnimationSpeed.toFloat()

   //setting position and rotation to the node
   fun animation(location: LOCATION, userPos: List<Float>?, isTapped: Boolean) {
      // If courtside, then we need to know which quadrant the user is in
      val quadrant = getQuadrant(Vector(userPos?.toFloatArray()))
      when (location) {
         LOCATION.COURTSIDE -> {
            when (quadrant) {
               basketballVenue.QUADRANT._0 -> {
                  //animate node to new position if isTapped is true else just setting new
                  // position to the node
                  if (isTapped) {
                     animateNode(
                        this.positionRealtime,
                        Vector((-1 * constants.courtHalfLength).toFloat(), 0f, distanceFromFloor),
                        this
                     )
                  } else {
                     this.setPosition(
                        Vector(
                           (-1 * constants.courtHalfLength).toFloat(), 0f, distanceFromFloor
                        )
                     )
                  }
                  this.rotationPivot = Vector(0.0, 0.0, 0.0)
                  val transform = Quaternion(0F, 0F, 0F, 1F)
                  val transformXAxis = transform.multiply(
                     Quaternion().makeRotation(
                        Math.toRadians(90.0).toFloat(), Vector(0f, 1f, 0f)
                     )
                  )
                  val transformYAxis = transformXAxis?.multiply(
                     Quaternion().makeRotation(
                        Math.toRadians(90.0).toFloat(), Vector(1f, 0f, 0f)
                     )
                  )
                  this.setRotation(transformYAxis)
               }
               basketballVenue.QUADRANT._90 -> {
                  //animate node to new position if isTapped is true else just setting new position to the node
                  if (isTapped) {
                     animateNode(
                        this.positionRealtime, Vector(
                           0f, (-1 * constants.courtHalfWidth).toFloat(), distanceFromFloor
                        ), this
                     )
                  } else {
                     this.setPosition(
                        Vector(
                           0f, (-1 * constants.courtHalfWidth).toFloat(), distanceFromFloor
                        )
                     )
                  }
                  this.rotationPivot = Vector(0.0, 0.0, 0.0)
                  this.setRotation(
                     Vector(-Math.PI / 2, Math.PI, 0.0)
                  )
               }
               basketballVenue.QUADRANT._180 -> {
                  //animate node to new position if isTapped is true else just setting new position to the node
                  if (isTapped) {
                     animateNode(
                        this.positionRealtime, Vector(
                           constants.courtHalfLength.toFloat(), 0f, distanceFromFloor
                        ), this
                     )
                  } else {
                     this.setPosition(
                        Vector(
                           constants.courtHalfLength.toFloat(), 0f, distanceFromFloor
                        )
                     )
                  }
                  this.rotationPivot = Vector(0.0, 0.0, 0.0)
                  val transform = Quaternion(0F, 0F, 0F, 1F)
                  val transformXAxis = transform.multiply(
                     Quaternion().makeRotation(
                        Math.toRadians(-90.0).toFloat(), Vector(0f, 1f, 0f)
                     )
                  )
                  val transformYAxis = transformXAxis?.multiply(
                     Quaternion().makeRotation(
                        Math.toRadians(90.0).toFloat(), Vector(1f, 0f, 0f)
                     )
                  )
                  this.setRotation(transformYAxis)
               }
               basketballVenue.QUADRANT._270 -> {
                  //animate node to new position if isTapped is true else just setting new position to the node
                  if (isTapped) {
                     animateNode(
                        this.positionRealtime, Vector(
                           0f, constants.courtHalfWidth.toFloat(), distanceFromFloor
                        ), this
                     )
                  } else {
                     this.setPosition(
                        Vector(
                           0f, constants.courtHalfWidth.toFloat(), distanceFromFloor
                        )
                     )
                  }
                  val transform = Quaternion(0F, 0F, 0F, 1F)
                  val transformXAxis = transform.multiply(
                     Quaternion().makeRotation(
                        Math.toRadians(90.0).toFloat(), Vector(1f, 0f, 0f)
                     )
                  )
                  this.setRotation(transformXAxis)
               }
            }
         }
         LOCATION.USER -> {
            // Get the unit direction vector from the user's location to center court
            userPos?.let {
               val viewDirection = (Vector(it[0] * -1, it[1] * -1, it[2] * -1)).normalize()

               // Place the board in front of the user some distance along the view-direction axis, where the bottom of the element is on top of the vector
               val positionAlongViewDirection = (Vector(userPos.toFloatArray()).add(
                  Vector(
                     viewDirection.x * distanceFromCamera,
                     viewDirection.y * distanceFromCamera,
                     viewDirection.z * distanceFromCamera
                  )
               )).add(
                  Vector(0.0, 0.0, 0.3 * constants.teamLeaderBoardScale)
               )
               //animate node to new position if isTapped is true else just setting new position to the node
               if (isTapped) {
                  animateNode(this.positionRealtime, positionAlongViewDirection, this)
               } else {
                  this.setPosition(positionAlongViewDirection)
               }

               //calculating rotation on y axis
               val xyRotation = atan2(userPos[1], userPos[0]) + Math.PI / 2
               this.rotationPivot = Vector(0.0, 0.0, 0.0)
               val transform = Quaternion(0F, 0F, 0F, 1F)
               val transformYAxis = transform.multiply(
                  Quaternion().makeRotation(
                     xyRotation.toFloat(), Vector(0f, 1f, 0f)
                  )
               )
               // Rotate upright
               val transformXAxis = transformYAxis.multiply(
                  Quaternion().makeRotation(
                     Math.toRadians(90.0).toFloat(), Vector(1f, 0f, 0f)
                  )
               )
               this.setRotation(transformXAxis)
            }
         }
      }
   }

   //for animating team leaderboard/playercard once tapped
   private fun animateNode(
      currentPosition: Vector?, newPosition: Vector, entity: Node
   ) {
      currentPosition?.let {
         var pointCount = 0

         //calculating distance between current position
         // and new position to calculate number of intermediate animation points
         pointCount = currentPosition.distance(newPosition).toInt()

         //calculating x,y,z value difference between nearest intermediate points
         val individualPointXDifference = (newPosition.x - it.x) / pointCount
         val individualPointYDifference = (newPosition.y - it.y) / pointCount
         val individualPointZDifference = (newPosition.z - it.z) / pointCount

         //creating intermediate vector positions
         val positionArray: ArrayList<Vector> = arrayListOf()
         for (index in 0 until pointCount) {
            positionArray.add(
               Vector(
                  it.x + ((index + 1) * individualPointXDifference),
                  it.y + ((index + 1) * individualPointYDifference),
                  it.z + ((index + 1) * individualPointZDifference)
               )
            )
         }

         //calculate animation delay between each point
         val animationDelay = (cardAnimationDelay / pointCount).toLong()

         //animate entity using timer
         var counter = 1
         var animationTimer: Timer? = null
         animationTimer = timer("ZoomAnimation", false, animationDelay, animationDelay) {
            if (counter < positionArray.size) {
               entity.setPosition(positionArray[counter - 1])
               counter++
            } else {
               animationTimer?.cancel()
            }
         }
      }
   }
}