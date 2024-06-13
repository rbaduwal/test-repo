package ai.quintar.q.ui.basketball

import ai.quintar.q.sportData.basketball.basketballGameChronicles.heatmaps
import android.graphics.Color
import android.net.Uri
import android.util.Log
import com.viro.core.*
import com.viro.core.Vector
import java.util.*


class basketballHeatMapSceneGraphNode(virocontext: ViroContext) {
   lateinit var heatmapText: Text
   var rootHeatmapEntity: Node
   var rootTextEntity: Node
   private var virocontext: ViroContext? = null

   init {
      this.virocontext = virocontext
      rootHeatmapEntity = Node()
      rootTextEntity = Node()
   }

   fun loadModel(heatmapModel: Array<String>) {
      for (heatmapItem in heatmapModel) {
         val heatmaps = Object3D()
         val filepath = "file:///android_asset/"
         heatmaps.setScale(Vector(1.0f, 1.0f, 1.0f))
         heatmaps.loadModel(virocontext,
            Uri.parse("$filepath$heatmapItem.obj"),
            Object3D.Type.OBJ,
            object : AsyncObject3DListener {
               override fun onObject3DFailed(error: String) {
                  Log.e("heatmap", "heat map Failed to load!")
               }

               override fun onObject3DLoaded(`object`: Object3D, type: Object3D.Type) {
                  val materials = heatmaps.materials
                  for (item in materials) {
                     item.diffuseColor = Color.TRANSPARENT
                  }
                  heatmaps.geometry.materials = materials
               }
            })
         rootHeatmapEntity.addChildNode(heatmaps)
      }
   }

   fun createTextEntity(
      pct: Int
   ) {

      //creating text with percentage
      heatmapText = Text(virocontext, "$pct%", 90f, 30f)
      heatmapText.extrusionDepth = 0.0001f
      heatmapText.fontWeight = Text.FontWeight.Bold
      heatmapText.fontStyle = Text.FontStyle.Normal
      val percentageTextNode = Node()
      percentageTextNode.geometry = heatmapText
      percentageTextNode.setScale(Vector(20f, 20f, 20f))

      //setting billboard y to textnode
      percentageTextNode.transformBehaviors = EnumSet.of(Node.TransformBehavior.BILLBOARD_Y)
      rootTextEntity.addChildNode(percentageTextNode)
   }

   fun setZoneColor(zoneIndex: Int, heatmapOpacity: Float?, heatmapColor: String?) {
      //getting heatmap in zone index and set colour and opacity to that
      val heatmapNode = rootHeatmapEntity.childNodes?.get(zoneIndex)
      val materials = heatmapNode?.geometry?.materials
      if (materials != null) {
         for (item in materials) {
            item?.let {
               heatmapColor?.let { color ->
                  it.diffuseColor = Color.parseColor(color)
               }
               heatmapOpacity?.let { opacity ->
                  heatmapNode.opacity = opacity
               }
            }
         }
      }
   }

   fun setHeatmapTextNodeHeight(
      position: Vector,
      heatmapPercentageValues: ArrayList<heatmaps>,
      completion: (d: Boolean) -> Unit
   ) {
      var nearestNodeIndex = 0
      var shortestDistance: Float? = null
      val textNodeCenterPoints: ArrayList<Vector> = arrayListOf()

      for (heatmapPercentage in heatmapPercentageValues) {
         heatmapPercentage.ci?.let { zoneIndex ->
            if (zoneIndex <= 13) {

               //calculating center position of the heatmap in local coordinate system
               val boundingBox = rootHeatmapEntity.childNodes[zoneIndex].boundingBoxLocal
               val centerX = (boundingBox.minX + boundingBox.maxX) / 2
               val centerY = (boundingBox.minY + boundingBox.maxY) / 2
               val centerZ = (boundingBox.minZ + boundingBox.maxZ) / 2
               val heatmapCenterPosition = Vector(centerX, centerY, centerZ)

               //calculating center position of the heatmap in world coordinate system
               val boundingBoxWorld = rootHeatmapEntity.childNodes[zoneIndex].boundingBox
               val centerWorldX = (boundingBoxWorld.minX + boundingBoxWorld.maxX) / 2
               val centerWorldY = (boundingBoxWorld.minY + boundingBoxWorld.maxY) / 2
               val centerWorldZ = (boundingBoxWorld.minZ + boundingBoxWorld.maxZ) / 2
               val heatmapCenterWorldPosition = Vector(centerWorldX, centerWorldY, centerWorldZ)

               //adding local center point to array
               textNodeCenterPoints.add(zoneIndex, heatmapCenterPosition)

               //finding distance of heatmap center in world coordinate system from camera
               val distanceFromCamera = position.distance(heatmapCenterWorldPosition)

               //finding node having shortest distance from camera
               if (shortestDistance == null) {
                  shortestDistance = distanceFromCamera
                  nearestNodeIndex = zoneIndex
               } else {
                  shortestDistance?.let {
                     if (distanceFromCamera < it) {
                        shortestDistance = distanceFromCamera
                        nearestNodeIndex = zoneIndex
                     }
                  }
               }
            }
         }
      }
      for (heatmapPercentage in heatmapPercentageValues) {
         heatmapPercentage.ci?.let { zoneIndex ->
            if (zoneIndex <= 13) {

               //finding distance of each heatmap node from nearest node from camera
               val distanceFromNearestNode =
                  textNodeCenterPoints[zoneIndex].distance(textNodeCenterPoints[nearestNodeIndex])

               //creating new z point by adding (distance*0.15) to the existing z value to
               // provide height
               val newZPoint = (textNodeCenterPoints[zoneIndex].z + distanceFromNearestNode) * 0.15

               //setting position to each text node with new z value
               rootTextEntity.childNodes[zoneIndex].setPosition(
                  Vector(
                     textNodeCenterPoints[zoneIndex].x,
                     textNodeCenterPoints[zoneIndex].y,
                     newZPoint.toFloat()
                  )
               )
            }
         }
      }
      completion(true)
   }
}